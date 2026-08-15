import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void removeSplashOverlay() {
  try {
    final document = globalContext['document'] as JSObject;
    final splash = document.callMethodVarArgs<JSAny?>(
      'querySelector'.toJS,
      <JSAny?>['#splash'.toJS],
    );
    (splash as JSObject)
        .callMethodVarArgs<JSAny?>('remove'.toJS, const <JSAny?>[]);
  } catch (_) {
    // falha silenciosa: splash já removido ou ausente no host
  }
}
