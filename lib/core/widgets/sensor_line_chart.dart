import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/sensor_reading.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SensorLineChart extends StatelessWidget {
  const SensorLineChart({
    super.key,
    required this.readings,
    required this.metric,
    this.height = 195,
  });

  final List<SensorReading> readings;
  final SensorMetricType metric;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Tidak ada data pada rentang ini.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final values = readings.map((r) => r.valueFor(metric)).toList();
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final minY = (rawMin * 0.95).floorToDouble();
    final maxY = math.max(minY + 1, (rawMax * 1.03).ceilToDouble());
    final interval = math.max(1.0, (maxY - minY) / 3.0);

    final spots = [
      for (int i = 0; i < readings.length; i++)
        FlSpot(i.toDouble(), readings[i].valueFor(metric)),
    ];

    final lastIndex = readings.length - 1;
    final midIndex = readings.length ~/ 2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, lastIndex).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE5EBE6),
              strokeWidth: 1,
              dashArray: [3, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: interval,
                getTitlesWidget: (val, meta) {
                  if (val > maxY + 0.01 || val < minY - 0.01) {
                    return const SizedBox.shrink();
                  }
                  final String label;
                  if (metric == SensorMetricType.water) {
                    label = val >= 50 ? 'Penuh' : 'Habis';
                  } else if (metric == SensorMetricType.temp) {
                    label = AppFormatters.decimal(val, digits: 1);
                  } else {
                    label = AppFormatters.integer(val);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.round();
                  if (idx != 0 && idx != midIndex && idx != lastIndex) {
                    return const SizedBox.shrink();
                  }
                  if (idx < 0 || idx >= readings.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      AppFormatters.timeHm(readings[idx].time),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.forest,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final idx = spot.x.round().clamp(0, readings.length - 1);
                final r = readings[idx];
                final valueStr = metric == SensorMetricType.temp
                    ? '${AppFormatters.decimal(r.temp)} °C'
                    : metric == SensorMetricType.ppm
                        ? '${AppFormatters.integer(r.ppm)} ppm'
                        : r.waterStatusLabel;
                return LineTooltipItem(
                  '$valueStr\n${AppFormatters.dateTimeShort(r.time)}',
                  const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.28,
              color: AppColors.green,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: readings.length <= 2,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF82AD7A).withValues(alpha: 0.28),
                    const Color(0xFF82AD7A).withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
