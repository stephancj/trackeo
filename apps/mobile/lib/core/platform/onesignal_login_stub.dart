// Stub mobile : le plugin Flutter onesignal_flutter gère login/logout nativement.
// Ces fonctions sont des no-ops sur iOS/Android.

void oneSignalLoginPlatform(String userId) {
  // no-op — handled by OneSignal.login() from the Flutter plugin on mobile
}

void oneSignalLogoutPlatform() {
  // no-op — handled by OneSignal.logout() from the Flutter plugin on mobile
}

/// Sur mobile, le subscription ID est géré nativement par le plugin.
/// Retourne null — l'enregistrement push-token n'est pas nécessaire sur mobile (MVP web uniquement).
String? getOneSignalSubId() => null;
