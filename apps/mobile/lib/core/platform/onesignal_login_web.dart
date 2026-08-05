// Implémentation web : appel via les fonctions async définies dans index.html
// qui awaite correctement les Promises OneSignal.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';

/// Appelle window.trackeoOneSignalLogin(userId) — async, await la Promise correctement.
/// window.OneSignal.login() retourne une Promise ; dart:js ne peut pas l'await
/// directement, donc on passe par une fonction JS intermédiaire dans index.html.
void oneSignalLoginPlatform(String userId) {
  try {
    js.context.callMethod('trackeoOneSignalLogin', [userId]);
  } catch (e) {
    // ignore si le SDK n'est pas encore prêt
  }
}

/// Appelle window.trackeoOneSignalLogout() — async, await la Promise.
void oneSignalLogoutPlatform() {
  try {
    js.context.callMethod('trackeoOneSignalLogout', []);
  } catch (e) {
    // ignore
  }
}

/// Retourne le subscription ID OneSignal courant (UUID de la subscription navigateur).
/// Null si l'utilisateur n'a pas encore accordé la permission push ou si le SDK
/// n'est pas encore initialisé.
String? getOneSignalSubId() {
  try {
    final result = js.context.callMethod('trackeoGetSubId', []);
    return result as String?;
  } catch (e) {
    return null;
  }
}

/// Demande la permission depuis un clic utilisateur, attend la création de la
/// subscription OneSignal, puis retourne son ID.
Future<String?> requestOneSignalSubscription(String userId) async {
  final completer = Completer<String?>();
  try {
    js.context.callMethod('trackeoSubscribePush', [
      userId,
      js.JsFunction.withThis((dynamic _, dynamic result) {
        if (!completer.isCompleted) {
          completer.complete(
            result is String && result.isNotEmpty ? result : null,
          );
        }
      }),
    ]);
  } catch (_) {
    if (!completer.isCompleted) completer.complete(null);
  }
  return completer.future.timeout(
    const Duration(seconds: 15),
    onTimeout: () => null,
  );
}

/// subscribed | denied | default | unsupported
String getOneSignalPermissionStatus() {
  try {
    final result = js.context.callMethod('trackeoGetPushStatus', []);
    return result is String ? result : 'unsupported';
  } catch (_) {
    return 'unsupported';
  }
}
