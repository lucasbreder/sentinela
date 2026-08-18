import 'package:image/image.dart' as img;

/// Aplica correções de imagem para melhorar a acurácia do OCR em fotos de
/// placas (pouca luz, contraste baixo, leve desfoque ou ruído de compressão).
///
/// A lógica de pixel é isolada em funções puras para permitir teste unitário.
abstract final class ImagePreprocessor {
  /// Aplica nível de cinza, contraste e binarização (Otsu).
  ///
  /// Evita desfoque (gaussianBlur): em texto pequeno o borrão reduz a
  /// legibilidade e prejudica o OCR de placas. A binarização gera texto preto
  /// sobre fundo branco, que o ML Kit lê com mais acerto em placas.
  static img.Image process(img.Image image) {
    var grayscale = img.grayscale(image);
    grayscale = img.adjustColor(grayscale, contrast: 1.3, brightness: 8);
    return deslash(binarize(grayscale));
  }

  /// Remove traços diagonais finos (o corte do zero Mercosul), que o OCR
  /// costuma ler como o "rabo" de um `6`, transformando o zero cortado em `6`.
  ///
  /// Opera sobre a imagem binarizada (preto/branco). Remove pixels de um traço
  /// puramente diagonal (sem vizinho ortogonal), que é o corte de ~1px; hastes
  /// de letras sólidas têm vizinhos ortogonais (espessura) e são preservadas.
  /// O processo é repetido até estabilizar para que a remoção em cascata
  /// elimine o traço inteiro, inclusive as pontas.
  static img.Image deslash(img.Image image) {
    final out = img.Image(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        out.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
      }
    }
    // Detecta sobre a imagem original (não modificada) e aplica na cópia, para
    // que todo o traço (incluindo as pontas, identificadas pelo suporte
    // diagonal) seja removido de uma vez.
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (_isBlack(image.getPixel(x, y)) && _isThinDiagonal(image, x, y)) {
          out.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }
    return out;
  }

  /// Verdadeiro se o pixel faz parte de um traço diagonal fino: tem suporte
  /// diagonal (em uma das duas diagonais), não é um cruzamento (centro do X) e
  /// não pertence a uma barra horizontal/vertical. Permite até um vizinho
  /// ortogonal, capturando o corte do zero levemente mais grosso (de perto);
  /// letras grossas têm muitos vizinhos ortogonais e são preservadas.
  static bool _isThinDiagonal(img.Image image, int x, int y) {
    final w = image.width;
    final h = image.height;
    final nw = x > 0 && y > 0 && _isBlack(image.getPixel(x - 1, y - 1));
    final ne = x < w - 1 && y > 0 && _isBlack(image.getPixel(x + 1, y - 1));
    final sw = x > 0 && y < h - 1 && _isBlack(image.getPixel(x - 1, y + 1));
    final se = x < w - 1 && y < h - 1 && _isBlack(image.getPixel(x + 1, y + 1));
    final n = y > 0 && _isBlack(image.getPixel(x, y - 1));
    final s = y < h - 1 && _isBlack(image.getPixel(x, y + 1));
    final e = x < w - 1 && _isBlack(image.getPixel(x + 1, y));
    final o = x > 0 && _isBlack(image.getPixel(x - 1, y));
    final diagA = nw || se;
    final diagB = ne || sw;
    if (!diagA && !diagB) return false;
    if (diagA && diagB) return false;
    if ((e && o) || (n && s)) return false;
    final ortho = [n, s, e, o].where((b) => b).length;
    return ortho <= 1;
  }

  static bool _isBlack(img.Pixel pixel) => pixel.r.toInt() < 128;

  /// Converte a imagem em preto-e-branco usando o limiar de Otsu, escolhido a
  /// partir do histograma de intensidade. Pixels com luminância acima do limiar
  /// viram branco (255); abaixo, preto (0).
  static img.Image binarize(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    for (final pixel in image) {
      histogram[pixel.r.toInt()]++;
    }
    final total = image.length;
    final threshold = _otsuThreshold(histogram, total);
    final out = img.Image(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final value = image.getPixel(x, y).r.toInt() > threshold ? 255 : 0;
        out.setPixelRgb(x, y, value, value, value);
      }
    }
    return out;
  }

  static int _otsuThreshold(List<int> histogram, int total) {
    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }
    var sumB = 0;
    var wB = 0;
    var maxVariance = -1.0;
    var threshold = 0;
    for (var i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;
      final wF = total - wB;
      if (wF == 0) break;
      sumB += i * histogram[i];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;
      final variance = wB * wF * (mB - mF) * (mB - mF);
      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }
    return threshold;
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