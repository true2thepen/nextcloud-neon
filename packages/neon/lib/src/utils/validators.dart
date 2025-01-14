part of '../neon.dart';

String? validateHttpUrl(
  final BuildContext context,
  final String? input, {
  final bool httpsOnly = false,
}) {
  if (input == null || input == '') {
    return AppLocalizations.of(context).errorInvalidURL;
  }
  try {
    final uri = Uri.parse(input);
    // TODO: Maybe make a better error message for http URLs if only https is allowed
    if (!(!httpsOnly && (uri.isScheme('http')) || uri.isScheme('https'))) {
      return AppLocalizations.of(context).errorInvalidURL;
    }
  } catch (e) {
    return AppLocalizations.of(context).errorInvalidURL;
  }
  return null;
}

String? validateNotEmpty(final BuildContext context, final String? input) {
  if (input == null || input == '') {
    return AppLocalizations.of(context).errorEmptyField;
  }

  return null;
}
