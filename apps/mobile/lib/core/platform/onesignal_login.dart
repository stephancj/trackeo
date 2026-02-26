// Export conditionnel : web → appel JS direct, mobile → stub (plugin natif)
export 'onesignal_login_stub.dart'
    if (dart.library.js) 'onesignal_login_web.dart';
