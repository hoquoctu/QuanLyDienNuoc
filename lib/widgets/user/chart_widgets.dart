import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TotalChart extends StatelessWidget {
  final List<Map<String, double>> data;
  const TotalChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final months = [
      'T1', 'T2', 'T3', 'T4', 'T5', 'T6',
      'T7', 'T8', 'T9', 'T10', 'T11', 'T12'
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng chi phí',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) => Text(
                            months[v.toInt() - 1],
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textHint)))),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: data
                  .map((d) => BarChartGroupData(
                      x: d['month']!.toInt(),
                      barRods: [
                        BarChartRodData(
                            toY: d['elec']! + d['water']!,
                            color: AppTheme.primary,
                            width: 24,
                            borderRadius: BorderRadius.circular(6))
                      ]))
                  .toList(),
            )),
          ),
        ],
      ),
    );
  }
}

class ElecWaterChart extends StatelessWidget {
  final List<Map<String, double>> data;
  const ElecWaterChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Điện & Nước',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              _Legend(color: AppTheme.elecColor, label: 'Điện'),
              const SizedBox(width: 12),
              _Legend(color: AppTheme.waterColor, label: 'Nước'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(LineChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
              titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false))),
              lineBarsData: [
                LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(
                        e.key.toDouble(), e.value['elec']!)).toList(),
                    isCurved: true,
                    color: AppTheme.elecColor,
                    barWidth: 3,
                    dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppTheme.elecColor)),
                    belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.elecColor.withOpacity(0.08))),
                LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(
                        e.key.toDouble(), e.value['water']!)).toList(),
                    isCurved: true,
                    color: AppTheme.waterColor,
                    barWidth: 3,
                    dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) =>
                            FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppTheme.waterColor)),
                    belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.waterColor.withOpacity(0.08))),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      );
}
