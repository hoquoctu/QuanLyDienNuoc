import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bh_room_model.dart';
import '../../models/bill_model.dart';
import '../../models/boarding_house_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bh_room_provider.dart';
import '../../providers/bill_provider.dart';
import '../../theme/app_theme.dart';
import 'bill_detail_screen.dart';

class DashboardUserScreen extends StatelessWidget {
  const DashboardUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final roomPvd = context.watch<BhRoomProvider>();
    final billPvd = context.watch<BillProvider>();

    final room = roomPvd.room;
    final bh = roomPvd.boardingHouse;
    final active = billPvd.activeBills;   // unpaid + pending
    final fmt = NumberFormat('#,###', 'vi_VN');

    // Chart data - last 5 months
    final chartData = _buildChartData(billPvd.bills);

    // Tiêu đề phòng hiển thị trên AppBar
    final String roomTitle;
    if (roomPvd.loading) {
      roomTitle = 'Đang tải...';
    } else if (room == null) {
      roomTitle = 'Chưa có phòng';
    } else if (room.bhRoomStatus == BhRoomStatus.waiting) {
      roomTitle = 'Phòng ${room.bhRoomNumber} · Chờ xác nhận';
    } else {
      roomTitle = '${bh?.bhName ?? 'Dãy trọ'} - Phòng ${room.bhRoomNumber}';
    }

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
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    if (bh != null && bh.bhAddress.isNotEmpty)
                      Text(
                        bh.bhAddress,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                // ── Loading / No room states ──────────────────────────────
                if (roomPvd.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (room == null)
                  _buildNoRoomBanner()
                else if (room.bhRoomStatus == BhRoomStatus.waiting)
                  _buildWaitingBanner(room)
                else ...[
                  // ── Room info card ──────────────────────────────────────
                  _buildRoomSummaryCard(room, bh),
                  const SizedBox(height: 16),

                  // ── Chỉ số điện/nước từ phòng Firestore ────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bolt,
                          iconColor: AppTheme.elecColor,
                          label: 'Chỉ số điện',
                          value:
                              '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                          trend: _calcTrend(billPvd.bills, isElec: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.water_drop,
                          iconColor: AppTheme.waterColor,
                          label: 'Chỉ số nước',
                          value:
                              '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
                          trend: _calcTrend(billPvd.bills, isElec: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Hóa đơn chưa thanh toán ──────────────────────────────
                if (billPvd.loading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ))
                else if (active.isNotEmpty) ...[                  const Text('Hóa đơn cần xử lý',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...active.map((bill) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BillDetailScreen(bill: bill),
                            ),
                          ),
                          child: _UnpaidCard(bill: bill, fmt: fmt),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // ── Biểu đồ chi phí ──────────────────────────────────────
                if (billPvd.bills.isNotEmpty) ...[
                  const Text('Biểu đồ chi phí điện nước',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  _TotalChart(data: chartData),
                  const SizedBox(height: 16),
                  _ElecWaterChart(data: chartData),
                  const SizedBox(height: 30),
                ] else if (!billPvd.loading &&
                    room != null &&
                    room.bhRoomStatus != BhRoomStatus.waiting) ...[
                  _buildNoInvoiceBanner(),
                  const SizedBox(height: 30),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner chưa có phòng ──────────────────────────────────────────────────
  Widget _buildNoRoomBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(24),
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
      child: const Column(
        children: [
          Icon(Icons.home_outlined, size: 52, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Chưa có phòng trọ',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 6),
          Text(
            'Vào tab "Phòng" để nhập mã và tham gia phòng trọ',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Banner đang chờ xác nhận ──────────────────────────────────────────────
  Widget _buildWaitingBanner(BhRoomModel room) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phòng ${room.bhRoomNumber} · Chờ xác nhận',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chủ trọ đang xét duyệt yêu cầu của bạn',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card tóm tắt phòng ────────────────────────────────────────────────────
  Widget _buildRoomSummaryCard(BhRoomModel room, BoardingHouseModel? bh) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bh?.bhName ?? 'Dãy trọ',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  'Phòng ${room.bhRoomNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary),
                ),
                if (bh != null && bh.bhAddress.isNotEmpty)
                  Text(
                    bh.bhAddress,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Đang thuê',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner chưa có hóa đơn ───────────────────────────────────────────────
  Widget _buildNoInvoiceBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppTheme.textHint),
          SizedBox(height: 10),
          Text('Chưa có hóa đơn nào',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  List<Map<String, double>> _buildChartData(List<BillModel> bills) {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final m = DateTime(now.year, now.month - (4 - i));
      final monthKey =
          '${m.year}-${m.month.toString().padLeft(2, '0')}'; // "2026-05"
      final matched = bills.where((b) => b.month == monthKey);
      final elec =
          matched.fold<double>(0, (sum, b) => sum + b.electric.total);
      final water =
          matched.fold<double>(0, (sum, b) => sum + b.water.total);
      return {'month': m.month.toDouble(), 'elec': elec, 'water': water};
    });
  }

  double? _calcTrend(List<BillModel> bills, {required bool isElec}) {
    if (bills.length < 2) return null;
    final curr = isElec ? bills[0].electric.used : bills[0].water.used;
    final prev = isElec ? bills[1].electric.used : bills[1].water.used;
    if (prev == 0) return null;
    return ((curr - prev) / prev) * 100;
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────
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
                  trend! >= 0 ? Icons.trending_up : Icons.trending_down,
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

// ── Unpaid / Active Bill Card ─────────────────────────────────────────────────
class _UnpaidCard extends StatelessWidget {
  final BillModel bill;
  final NumberFormat fmt;
  const _UnpaidCard({required this.bill, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (bill.status) {
      case BillStatus.pending:
        statusColor = const Color(0xFFF59E0B); // amber
        statusLabel = 'Chờ xác nhận';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case BillStatus.overdue:
        statusColor = Colors.deepOrange;
        statusLabel = 'Quá hạn';
        statusIcon = Icons.warning_rounded;
        break;
      default: // unpaid
        statusColor = AppTheme.errorColor;
        statusLabel = 'Chờ thanh toán';
        statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.monthLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(statusLabel,
                    style: TextStyle(fontSize: 12, color: statusColor)),
              ],
            ),
          ),
          Text(
            '${fmt.format(bill.total)}đ',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: statusColor,
                fontSize: 15),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textHint),
        ],
      ),
    );
  }
}

// ── Total Chart ──────────────────────────────────────────────────────────────
class _TotalChart extends StatelessWidget {
  final List<Map<String, double>> data;
  const _TotalChart({required this.data});

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
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                  return BarChartGroupData(
                      x: d['month']!.toInt(),
                      barRods: [
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

// ── Elec Water Chart ─────────────────────────────────────────────────────────
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
                      return FlSpot(e.key.toDouble(), e.value['elec']!);
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
                      return FlSpot(e.key.toDouble(), e.value['water']!);
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
