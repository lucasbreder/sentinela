import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

/// Executa OCR no navegador usando Tesseract.js (carregado no `web/index.html`).
///
/// Converte os bytes da imagem em um data URL e devolve todo o texto
/// reconhecido; a extração da placa é feita pelo [PlateExtractor] no chamador.
///
/// O worker do Tesseract e o `eng.traineddata` são criados uma única vez
/// ([ensureTesseractReady]) e reutilizados entre chamadas, evitando o atraso
/// de download/init a cada foto. Também restringe o conjunto de caracteres e o
/// modo de segmentação para melhorar a leitura de placas.
///
/// Por isso as chamadas ficam expostas como funções top-level injetáveis,
/// mantendo o padrão de dependência do restante do app.

/// Worker reutilizável entre chamadas (vive enquanto a página não é recarregada).
JSObject? _worker;

/// Marca se o worker já foi criado e configurado.
bool _ready = false;

/// Pré-carrega e configura o worker do Tesseract (traineddata + parâmetros).
///
/// Seguro chamar várias vezes: a inicialização só acontece na primeira.
Future<void> ensureTesseractReady({void Function(String? status)? onStatus}) async {
  if (_ready) return;
  final tesseract = globalContext['Tesseract'];
  if (tesseract == null) {
    throw StateError('Tesseract.js não está carregado');
  }
  onStatus?.call('Carregando motor de OCR...');

  // v5: createWorker(langs, oem, options). OEM 0 = LSTM (mais preciso).
  final createPromise = (tesseract as JSObject).callMethodVarArgs<JSAny?>(
    'createWorker'.toJS,
    ['eng'.toJS, 0.toJS],
  );
  final worker = await ((createPromise as JSPromise<JSAny?>).toDart) as JSObject?;
  if (worker == null) {
    throw StateError('Falha ao criar o worker do Tesseract');
  }

  // Restringe o charset e usa PSM 7 (linha única) para focar em placas.
  final params = JSObject();
  params['tessedit_char_whitelist'] =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'.toJS;
  params['tessedit_pageseg_mode'] = 7.toJS;
  final setPromise = worker.callMethodVarArgs<JSAny?>(
    'setParameters'.toJS,
    [params],
  );
  await (setPromise as JSPromise<JSAny?>).toDart;

  _worker = worker;
  _ready = true;
}

/// Reconhece o texto de uma imagem no navegador.
///
/// [onProgress] recebe o progresso (0..1) e o status do Tesseract, quando
/// disponível, permitindo exibir um indicador real de avanço.
Future<String> webOcrText(
  Uint8List imageBytes,
  String mime, {
  void Function(double? progress, String? status)? onProgress,
}) async {
  await ensureTesseractReady();

  final dataUrl = 'data:$mime;base64,${base64Encode(imageBytes)}';

  final jobOptions = JSObject();
  if (onProgress != null) {
    void logger(JSAny? value) {
      final obj = value as JSObject?;
      final status = (obj?['status'] as JSString?)?.toDart;
      final progress = (obj?['progress'] as JSNumber?)?.toDartDouble;
      onProgress(progress, status);
    }

    jobOptions['logger'] = logger.toJS;
  }

  final promise = _worker!.callMethodVarArgs<JSAny?>(
    'recognize'.toJS,
    [dataUrl.toJS, jobOptions],
  );
  final result = await ((promise as JSPromise<JSAny?>).toDart) as JSObject?;
  final data = result?['data'] as JSObject?;
  final text = data?['text'] as JSString?;
  return text?.toDart ?? '';
}