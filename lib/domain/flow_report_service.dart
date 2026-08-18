import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/data/models/registry.dart';

/// Quantidade de entradas e saídas em uma determinada hora do dia.
class HourlyFlow {
  const HourlyFlow({required this.hour, required this.entradas, required this.saidas});

  final int hour;
  final int entradas;
  final int saidas;

  int get total => entradas + saidas;
}

abstract final class FlowReportService {
  /// Agrupa as movimentações por hora do dia (0-23) contando entradas e saídas.
  static List<HourlyFlow> hourly(List<Registry> registries) {
    final entradas = List<int>.filled(24, 0);
    final saidas = List<int>.filled(24, 0);

    for (final registry in registries) {
      final hour = registry.createdAt.hour;
      if (hour < 0 || hour > 23) continue;
      if (registry.type == MovementType.entrada) {
        entradas[hour] += 1;
      } else if (registry.type == MovementType.saida) {
        saidas[hour] += 1;
      }
    }

    return List.generate(
      24,
      (hour) => HourlyFlow(hour: hour, entradas: entradas[hour], saidas: saidas[hour]),
    );
  }
}
