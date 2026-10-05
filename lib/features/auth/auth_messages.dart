import '../../data/auth_repository.dart';
import '../../l10n/app_localizations.dart';

String authErrorText(AppLocalizations l10n, Object error) {
  if (error is! AuthFailure) return l10n.errorUnknown;
  return switch (error.kind) {
    AuthFailureKind.invalidPhone => l10n.errorInvalidPhone,
    AuthFailureKind.invalidCode => l10n.errorInvalidCode,
    AuthFailureKind.codeExpired => l10n.errorCodeExpired,
    AuthFailureKind.tooManyRequests => l10n.errorTooManyRequests,
    AuthFailureKind.network => l10n.errorNetwork,
    AuthFailureKind.unknown => l10n.errorUnknown,
  };
}
