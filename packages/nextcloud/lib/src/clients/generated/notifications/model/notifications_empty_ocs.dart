//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.12

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationsEmptyOcs {
  /// Returns a new [NotificationsEmptyOcs] instance.
  NotificationsEmptyOcs({
    this.meta,
    this.data = const [],
  });

  /// Stub
  Object? meta;

  List<String> data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NotificationsEmptyOcs && other.meta == meta && other.data == data;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (meta == null ? 0 : meta!.hashCode) + (data.hashCode);

  @override
  String toString() => 'NotificationsEmptyOcs[meta=$meta, data=$data]';

  Map<String, dynamic> toJson() {
    final _json = <String, dynamic>{};
    if (meta != null) {
      _json[r'meta'] = meta;
    } else {
      _json[r'meta'] = null;
    }
    _json[r'data'] = data;
    return _json;
  }

  /// Returns a new [NotificationsEmptyOcs] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationsEmptyOcs? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "NotificationsEmptyOcs[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "NotificationsEmptyOcs[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return NotificationsEmptyOcs(
        meta: mapValueOfType<Object>(json, r'meta'),
        data: json[r'data'] is List ? (json[r'data'] as List).cast<String>() : const [],
      );
    }
    return null;
  }

  static List<NotificationsEmptyOcs>? listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <NotificationsEmptyOcs>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationsEmptyOcs.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationsEmptyOcs> mapFromJson(dynamic json) {
    final map = <String, NotificationsEmptyOcs>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationsEmptyOcs.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationsEmptyOcs-objects as value to a dart map
  static Map<String, List<NotificationsEmptyOcs>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<NotificationsEmptyOcs>>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationsEmptyOcs.listFromJson(
          entry.value,
          growable: growable,
        );
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}