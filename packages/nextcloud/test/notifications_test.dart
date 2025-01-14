import 'dart:async';
import 'dart:io';

import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud_push_proxy/nextcloud_push_proxy.dart';
import 'package:test/test.dart';

import 'helper.dart';

Future main() async {
  final image = await getDockerImage();

  group('notifications', () {
    late DockerContainer container;
    late TestNextcloudClient client;
    setUp(() async {
      container = await getDockerContainer(image);
      client = await getTestClient(
        container,
        username: 'admin',
        password: 'admin',
      );
    });
    tearDown(() => container.destroy());

    Future sendTestNotification() async {
      await client.notifications.sendAdminNotification(
        userId: 'admin',
        shortMessage: '123',
        longMessage: '456',
      );
    }

    test('Send admin notification', () async {
      await sendTestNotification();
    });

    test('List notifications', () async {
      await sendTestNotification();

      final startTime = DateTime.now().toUtc();
      final response = await client.notifications.listNotifications();
      expect(response.ocs.data, hasLength(1));
      expect(response.ocs.data[0].notificationId, 1);
      expect(response.ocs.data[0].app, 'admin_notifications');
      expect(response.ocs.data[0].user, 'admin');
      expectDateInReasonableTimeRange(DateTime.parse(response.ocs.data[0].datetime), startTime);
      expect(response.ocs.data[0].objectType, 'admin_notifications');
      expect(response.ocs.data[0].objectId, isNotNull);
      expect(response.ocs.data[0].subject, '123');
      expect(response.ocs.data[0].message, '456');
      expect(response.ocs.data[0].link, '');
      expect(response.ocs.data[0].subjectRich, '');
      expect(response.ocs.data[0].subjectRichParameters.mapStringDynamic, null);
      expect(response.ocs.data[0].messageRich, '');
      expect(response.ocs.data[0].messageRichParameters.mapStringDynamic, null);
      expect(response.ocs.data[0].icon, isNotEmpty);
      expect(response.ocs.data[0].actions, hasLength(0));
    });

    test('Get notification', () async {
      await sendTestNotification();

      final startTime = DateTime.now().toUtc();
      final response = await client.notifications.getNotification(id: 1);
      expect(response.ocs.data.notificationId, 1);
      expect(response.ocs.data.app, 'admin_notifications');
      expect(response.ocs.data.user, 'admin');
      expectDateInReasonableTimeRange(DateTime.parse(response.ocs.data.datetime), startTime);
      expect(response.ocs.data.objectType, 'admin_notifications');
      expect(response.ocs.data.objectId, isNotNull);
      expect(response.ocs.data.subject, '123');
      expect(response.ocs.data.message, '456');
      expect(response.ocs.data.link, '');
      expect(response.ocs.data.subjectRich, '');
      expect(response.ocs.data.subjectRichParameters.mapStringDynamic, null);
      expect(response.ocs.data.messageRich, '');
      expect(response.ocs.data.messageRichParameters.mapStringDynamic, null);
      expect(response.ocs.data.icon, isNotEmpty);
      expect(response.ocs.data.actions, hasLength(0));
    });

    test('Delete notification', () async {
      await sendTestNotification();
      await client.notifications.deleteNotification(id: 1);

      final response = await client.notifications.listNotifications();
      expect(response.ocs.data, hasLength(0));
    });

    test('Delete all notifications', () async {
      await sendTestNotification();
      await sendTestNotification();
      await client.notifications.deleteAllNotifications();

      final response = await client.notifications.listNotifications();
      expect(response.ocs.data, hasLength(0));
    });
  });

  group('push notifications', () {
    late DockerContainer container;
    late TestNextcloudClient client;
    setUp(() async {
      container = await getDockerContainer(image);
      client = await getTestClient(
        container,
        username: 'admin',
        // We need to use app passwords in order to register push devices
        useAppPassword: true,
      );
    });
    tearDown(() => container.destroy());

    // The key size has to be 2048, other sizes are not accepted by Nextcloud (at the moment at least)
    // ignore: avoid_redundant_argument_values
    RSAKeypair generateKeypair() => RSAKeypair.fromRandom(keySize: 2048);

    test('Register device and receive notification', () async {
      const pushToken = '789';
      final keypair = generateKeypair();

      final pushProxy = NextcloudPushProxy();

      late int port;
      while (true) {
        port = randomPort();
        try {
          await pushProxy.create(
            logging: false,
            port: port,
          );
          break;
        } on SocketException catch (e) {
          if (e.osError?.errorCode != 98) {
            rethrow;
          }
        }
      }

      final subscription = (await client.notifications.registerDevice(
        pushTokenHash: client.notifications.generatePushTokenHash(pushToken),
        devicePublicKey: keypair.publicKey.toFormattedPEM(),
        proxyServer: 'http://host.docker.internal:$port/',
      ))
          .ocs
          .data;
      expect(subscription.publicKey, hasLength(451));
      RSAPublicKey.fromPEM(subscription.publicKey);
      expect(subscription.deviceIdentifier, isNotEmpty);
      expect(subscription.signature, isNotEmpty);
      expect(subscription.message, isNull);

      final deviceCompleter = Completer();
      final notificationCompleter = Completer();

      pushProxy.onNewDevice.listen((final device) async {
        expect(device.pushToken, pushToken);
        expect(device.deviceIdentifier, isNotEmpty);
        expect(device.deviceIdentifierSignature, isNotEmpty);
        expect(device.userPublicKey, isNotEmpty);

        deviceCompleter.complete();
      });
      pushProxy.onNewNotification.listen((final notification) async {
        expect(notification.deviceIdentifier, subscription.deviceIdentifier);
        expect(notification.pushTokenHash, client.notifications.generatePushTokenHash(pushToken));
        expect(notification.subject, isNotEmpty);
        expect(notification.signature, isNotEmpty);
        expect(notification.priority, 'normal');
        expect(notification.type, 'alert');

        final decryptedSubject = decryptPushNotificationSubject(
          keypair.privateKey,
          notification.subject,
        );
        expect(decryptedSubject.nid, isNotNull);
        expect(decryptedSubject.app, 'admin_notifications');
        expect(decryptedSubject.subject, '123');
        expect(decryptedSubject.type, 'admin_notifications');
        expect(decryptedSubject.id, isNotEmpty);

        notificationCompleter.complete();
      });

      await client.notifications.registerDeviceAtPushProxy(
        pushToken,
        subscription,
        'http://localhost:$port/',
      );
      await client.notifications.sendAdminNotification(
        userId: 'admin',
        shortMessage: '123',
        longMessage: '456',
      );

      await deviceCompleter.future;
      await notificationCompleter.future;
      await pushProxy.close();
    });

    test('Remove push device', () async {
      const pushToken = '789';
      final keypair = generateKeypair();

      final subscription = (await client.notifications.registerDevice(
        pushTokenHash: client.notifications.generatePushTokenHash(pushToken),
        devicePublicKey: keypair.publicKey.toFormattedPEM(),
        proxyServer: 'https://example.com/',
      ))
          .ocs
          .data;
      expect(subscription.publicKey, hasLength(451));
      RSAPublicKey.fromPEM(subscription.publicKey);
      expect(subscription.deviceIdentifier, isNotEmpty);
      expect(subscription.signature, isNotEmpty);
      expect(subscription.message, isNull);

      await client.notifications.removeDevice();
    });
  });
}
