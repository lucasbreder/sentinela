import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Executa OCR no navegador usando Tesseract.js (carregado no `web/index.html`).
///
/// Converte os bytes da imagem em um data URL e devolve todo o texto
/// reconhecido; a extração da placa é feita pelo [PlateExtractor] no chamador.
Future<String> webOcrText(Uint8List imageBytes, String mime) async {
  final tesseract = globalContext['Tesseract'];
  if (tesseract == null) {
    throw StateError('Tesseract.js não está carregado');
  }

  final dataUrl = 'data:$mime;base64,${base64Encode(imageBytes)}';
  final promise = (tesseract as JSObject).callMethodVarArgs<JSAny?>(
    'recognize'.toJS,
    [dataUrl.toJS, 'eng'.toJS],
  );
  if (promise == null) {
    throw StateError('Falha ao iniciar o OCR');
  }

  final result = await (promise as JSPromise<JSAny?>).toDart;
  final resultObj = result as JSObject?;
  final data = resultObj?['data'] as JSObject?;
  final text = data?['text'] as JSString?;
  return text?.toDart ?? '';
}
