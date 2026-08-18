import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/domain/flow_report_service.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class HourlyFlowChart extends StatelessWidget {
  const HourlyFlowChart({super.key, required this.flow});

  final List<HourlyFlow> flow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SecondaryTitle(title: 'Fluxo por horário'),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              barGroups: [
                for (var i = 0; i < flow.length; i++)
                  BarChartGroupData(
                    x: flow[i].hour,
                    barRods: [
                      BarChartRodData(
                        toY: flow[i].entradas.toDouble(),
                        color: colors.primary,
                        width: 4,
                      ),
                      BarChartRodData(
                        toY: flow[i].saidas.toDouble(),
                        color: colors.error,
                        width: 4,
                      ),
                    ],
                  ),
              ],
              alignment: BarChartAlignment.spaceAround,
              maxY: _maxY(flow).toDouble(),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 3 != 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colors.surface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = flow[group.x];
                    final label = rodIndex == 0 ? 'Entradas' : 'Saídas';
                    return BarTooltipItem(
                      '${data.hour}h\n$label: ${rod.toY.toInt()}',
                      TextStyle(
                        color: rodIndex == 0 ? colors.primary : colors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: colors.primary, label: 'Entradas'),
            const SizedBox(width: 16),
            _Legend(color: colors.error, label: 'Saídas'),
          ],
        ),
      ],
    );
  }

  int _maxY(List<HourlyFlow> flow) {
    final max = flow.fold<int>(0, (acc, h) {
      final bigger = h.entradas > h.saidas ? h.entradas : h.saidas;
      return bigger > acc ? bigger : acc;
    });
    return max == 0 ? 1 : max;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
