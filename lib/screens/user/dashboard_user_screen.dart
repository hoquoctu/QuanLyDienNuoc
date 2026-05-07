import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/room_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'invoice_detail_screen.dart';

class DashboardUserScreen extends StatelessWidget {
  const DashboardUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final invPvd = context.watch<InvoiceProvider>();
    final roomPvd = context.watch<RoomProvider>();
    final room = roomPvd.roomForTenant(user.id);
    final invoices = invPvd.invoicesForTenant(user.id);
    final unpaid = invoices
        .where((i) =>
            i.status == InvoiceStatus.waitingPayment ||
            i.status == InvoiceStatus.pendingConfirm)
        .toList();
    final fmt = NumberFormat('#,###', 'vi_VN');

    // Chart data - last 5 months
    final chartData = _buildChartData(invoices);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Xin chào, ${user.name.split(' ').last}! 👋',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room != null
                          ? '${room.blockId} - Phòng ${room.name}'
                          : 'Chưa có phòng',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('Tổng quan',
                style: TextStyle(color: Colors.white)),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt,
                        iconColor: AppTheme.elecColor,
                        label: 'Điện tháng này',
                        value: invoices.isNotEmpty
                            ? '${fmt.format(invoices.first.elecUsed)} kWh'
                            : '-- kWh',
                        trend: _calcTrend(invoices, isElec: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.water_drop,
                        iconColor: AppTheme.waterColor,
                        label: 'Nước tháng này',
                        value: invoices.isNotEmpty
                            ? '${fmt.format(invoices.first.waterUsed)} m³'
                            : '-- m³',
                        trend: _calcTrend(invoices, isElec: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unpaid invoices alert
                if (unpaid.isNotEmpty) ...[
                  const Text('Hóa đơn chờ thanh toán',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...unpaid.map((inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoiceDetailScreen(invoice: inv),
                            ),
                          ),
                          child: _UnpaidCard(invoice: inv, fmt: fmt),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Chart total
                const Text('Biểu đồ chi phí điện nước',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                _TotalChart(data: chartData),
                const SizedBox(height: 16),

                // Chart elec+water
                _ElecWaterChart(data: chartData),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, double>> _buildChartData(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final m = DateTime(now.year, now.month - (4 - i));
      final inv = invoices.where((inv) =>
          inv.createdAt.year == m.year &&
          inv.createdAt.month == m.month);
      final elec =
          inv.fold<double>(0, (sum, i) => sum + i.elecTotal);
      final water =
          inv.fold<double>(0, (sum, i) => sum + i.waterTotal);
      return {'month': m.month.toDouble(), 'elec': elec, 'water': water};
    });
  }

  double? _calcTrend(List<InvoiceModel> invoices, {required bool isElec}) {
    if (invoices.length < 2) return null;
    final curr = isElec ? invoices[0].elecUsed : invoices[0].waterUsed;
    final prev = isElec ? invoices[1].elecUsed : invoices[1].waterUsed;
    if (prev == 0) return null;
    return ((curr - prev) / prev) * 100;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double? trend;
  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value,
      this.trend});

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trend! >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: trend! >= 0
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Text(
                  '${trend!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: trend! >= 0
                        ? AppTheme.errorColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UnpaidCard extends StatelessWidget {
  final InvoiceModel invoice;
  final NumberFormat fmt;
  const _UnpaidCard({required this.invoice, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${invoice.blockName} - ${invoice.roomName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700)),
                StatusBadge.invoice(invoice.status),
              ],
            ),
          ),
          Text(
            '${fmt.format(invoice.grandTotal)}đ',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.errorColor,
                fontSize: 15),
          ),
          const Icon(Icons.chevron_right,
              color: AppTheme.textHint),
        ],
      ),
    );
  }
}

class _TotalChart extends StatelessWidget {
  final List<Map<String, double>> data;
  const _TotalChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final months = ['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];
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
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        months[v.toInt() - 1],
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textHint),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.map((d) {
                  final total = d['elec']! + d['water']!;
                  return BarChartGroupData(x: d['month']!.toInt(), barRods: [
                    BarChartRodData(
                      toY: total,
                      color: AppTheme.primary,
                      width: 24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElecWaterChart extends StatelessWidget {
  final List<Map<String, double>> data;
  const _ElecWaterChart({required this.data});

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
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              _Legend(color: AppTheme.elecColor, label: 'Điện'),
              const SizedBox(width: 12),
              _Legend(color: AppTheme.waterColor, label: 'Nước'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                          e.key.toDouble(), e.value['elec']!);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.elecColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: AppTheme.elecColor,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.elecColor.withOpacity(0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                          e.key.toDouble(), e.value['water']!);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.waterColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: AppTheme.waterColor,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.waterColor.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}
