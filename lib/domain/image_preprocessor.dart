import 'package:image/image.dart' as img;

/// Aplica correções de imagem para melhorar a acurácia do OCR em fotos de
/// placas (pouca luz, contraste baixo, leve desfoque ou ruído de compressão).
///
/// A lógica de pixel é isolada em funções puras para permitir teste unitário.
abstract final class ImagePreprocessor {
  /// Aplica nível de cinza e ajuste de contraste/brilho.
  ///
  /// Evita desfoque (gaussianBlur): em texto pequeno o borrão reduz a
  /// legibilidade e prejudica o OCR de placas.
  static img.Image process(img.Image image) {
    var grayscale = img.grayscale(image);
    grayscale = img.adjustColor(grayscale, contrast: 1.3, brightness: 8);
    return grayscale;
  }

  /// Amplia a imagem para que textos pequenos fiquem grandes o suficiente para
  /// o OCR ler. Tesseract/ML Kit acertam mais em texto ampliado e limpo.
  static img.Image upscale(img.Image image, {int minTarget = 1600}) {
    final maxDim = image.width > image.height ? image.width : image.height;
    if (maxDim >= minTarget) return image;
    final scale = minTarget / maxDim;
    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
}