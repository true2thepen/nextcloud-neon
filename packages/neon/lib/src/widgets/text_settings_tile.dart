// ignore_for_file: use_late_for_private_fields_and_variables
// ^ This is a really strange false positive, it goes of at a very random place without any meaning. Hopefully fixed soon?

part of '../neon.dart';

class TextSettingsTile extends SettingsTile {
  const TextSettingsTile({
    required this.text,
    this.style,
    super.key,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Text(
          text,
          style: style,
        ),
      );
}
