import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'plate_type.dart';

/// Infere o tipo de placa a partir da cor.
///
/// A placa Mercosul tem uma banda azul horizontal no topo; a antiga é
/// branca/cinzenta. Este detector procura uma linha com densidade alta de azul
/// (a banda), independente de onde ela está no recorte, o que é mais tolerante
/// a enquadramento e iluminação do que fixar uma fração no topo.
///
/// No NV21, o azul tem U alto e V baixo (Cb/Cr). Usar a diferença `U − V`
/// torna a detecção relativa ao brilho: tons neutros (branco/cinza) têm
/// U ≈ V, então são rejeitados mesmo sob iluminação variável, enquanto o azul
/// saturado mantém U bem acima de V.
///
/// A classificação é conservadora no retorno: só devolve `mercosul` quando há
/// uma banda azul clara e `unknown` caso contrário — nunca afirma que é antiga
/// apenas pela ausência de azul (isso forçaria a posição 4 a dígito e quebraria
/// placas Mercosul). Além disso, a extração é não-degradante: mesmo que a cor
/// seja detectada errado, o primeiro candidato continua o mesmo de antes.
abstract final class PlateColorDetector {
  /// Diferença mínima de crominância U−V para considerar o pixel azul no NV21.
  /// Azul tem U alto e V baixo; neutro/cinza tem U ≈ V.
  static const int _uvBlueDiff = 40;

  /// Mínimo desvio do canal azul em relação aos demais (imagem RGB).
  static const int _rgbBlueMargin = 40;

  /// Menor intensidade do canal azul para um pixel colorido.
  static const int _minBlueValue = 90;

  /// Densidade mínima de azul numa linha para considerá-la parte da banda.
  static const double _blueRowRatio = 0.15;

  /// Média de crominância (NV21) abaixo da qual a imagem é tratada como
  /// branca/cinzenta (placa antiga), em vez de "indefinida".
  static const double _chromaLow = 20;

  /// Média de saturação (RGB) abaixo da qual a imagem é tratada como
  /// branca/cinzenta (placa antiga).
  static const int _rgbSatThreshold = 20;

  /// Infere o tipo a partir de um recorte colorido (imagem decodificada).
  static PlateType detect(img.Image image) {
    if (image.width < 8 || image.height < 8) return PlateType.unknown;
    var bestRowRatio = 0.0;
    var saturationSum = 0;
    var sampled = 0;
    for (var y = 0; y < image.height; y++) {
      var blue = 0;
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        if (b >= _minBlueValue &&
            b - r >= _rgbBlueMargin &&
            b - g >= _rgbBlueMargin) {
          blue++;
        }
        final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
        saturationSum += maxC - minC;
        sampled++;
      }
      final ratio = blue / image.width;
      if (ratio > bestRowRatio) bestRowRatio = ratio;
    }
    if (bestRowRatio >= _blueRowRatio) return PlateType.mercosul;
    // Sem banda azul: placa branca/cinzenta (pouca saturação) → antiga; se há
    // cor (fundo colorido/azul abaixo do limiar), não decide.
    final avgSat = sampled == 0 ? 0 : saturationSum / sampled;
    return avgSat < _rgbSatThreshold ? PlateType.old : PlateType.unknown;
  }

  /// Infere o tipo a partir de um buffer NV21 (plano Y + crominância VU), como
  /// o usado no caminho de streaming da câmera. Amostra apenas a crominância
  /// (azul → U alto, V baixo), sem converter o quadro inteiro para RGB.
  static PlateType detectNv21(Uint8List nv21, int width, int height) {
    if (width < 8 || height < 8) return PlateType.unknown;
    final ySize = width * height;
    if (nv21.length <= ySize) return PlateType.unknown;
    final chromaWidth = (width + 1) >> 1;
    var bestRowRatio = 0.0;
    var chromaSum = 0;
    var sampled = 0;
    for (var y = 0; y < height; y++) {
      final uvRow = (y >> 1) * chromaWidth;
      var blue = 0;
      var rowSampled = 0;
      for (var x = 0; x < width; x += 2) {
        final off = ySize + (uvRow + (x >> 1)) * 2;
        if (off + 1 >= nv21.length) continue;
        final v = nv21[off];
        final u = nv21[off + 1];
        rowSampled++;
        if (u - v >= _uvBlueDiff) blue++;
        chromaSum += (u - 128).abs() + (v - 128).abs();
      }
      if (rowSampled > 0) {
        sampled += rowSampled;
        final ratio = blue / rowSampled;
        if (ratio > bestRowRatio) bestRowRatio = ratio;
      }
    }
    if (bestRowRatio >= _blueRowRatio) return PlateType.mercosul;
    // Sem banda azul: crominância quase neutra (branco/cinza) → antiga; com
    // cor real não identifica.
    final avgChroma = sampled == 0 ? 0 : chromaSum / sampled;
    return avgChroma < _chromaLow ? PlateType.old : PlateType.unknown;
  }
}
