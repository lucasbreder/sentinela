import 'package:image/image.dart' as img;

/// Aplica correções de imagem para melhorar a acurácia do OCR em fotos de
/// placas (pouca luz, contraste baixo, leve desfoque ou ruído de compressão).
///
/// A lógica de pixel é isolada em funções puras para permitir teste unitário.
abstract final class ImagePreprocessor {
  /// Aplica nível de cinza, ajuste de contraste/brilho e redução de ruído.
  static img.Image process(img.Image image) {
    var grayscale = img.grayscale(image);
    grayscale = img.adjustColor(grayscale, contrast: 1.3, brightness: 8);
    return img.gaussianBlur(grayscale, radius: 1);
  }
}
