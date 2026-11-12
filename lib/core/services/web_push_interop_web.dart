// Implementação de interoperabilidade Web Push (PWA) via dart:js_interop
import 'dart:js_interop';

@JS('boragasPushRequestPermission')
external JSPromise<JSBoolean> _boragasPushRequestPermission();

@JS('boragasPushLogin')
external JSPromise<JSBoolean> _boragasPushLogin(JSString userId);

@JS('boragasPushLogout')
external JSPromise<JSBoolean> _boragasPushLogout();

@JS('boragasGetSubscriptionId')
external JSString? _boragasGetSubscriptionId();

Future<bool> webRequestPushPermission() async {
  try {
    final result = await _boragasPushRequestPermission().toDart;
    return result.toDart;
  } catch (_) {
    return false;
  }
}

void webLoginPush(String userId) {
  try {
    _boragasPushLogin(userId.toJS);
  } catch (_) {}
}

void webLogoutPush() {
  try {
    _boragasPushLogout();
  } catch (_) {}
}

String? webGetSubscriptionId() {
  try {
    return _boragasGetSubscriptionId()?.toDart;
  } catch (_) {
    return null;
  }
}
