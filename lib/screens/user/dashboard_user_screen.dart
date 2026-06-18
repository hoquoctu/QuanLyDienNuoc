import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/bh_room_provider.dart';
import 'package:quanlydiennc_app/providers/user/bill_provider_user.dart';
import '../../models/bh_room_model.dart';
import '../../models/bill_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/chart_widgets.dart';
import '../../widgets/user/notification_bell.dart';
import '../../widgets/user/stat_card.dart';
import '../../widgets/user/unpaid_card.dart';
import 'bill_detail_screen.dart';

class DashboardUserScreen extends StatelessWidget {
  const DashboardUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final roomPvd = context.watch<BhRoomProviderUser>();
    final billPvd = context.watch<BillProviderUser>();
    final validBills = billPvd.bills
        .where((b) => b.billStatus != BillStatus.cancelled)
        .toList();
    final rooms = roomPvd.rooms;
    final activeRooms = roomPvd.activeRooms;
    final active = billPvd.activeBills;
    final fmt = NumberFormat('#,###', 'vi_VN');
    final chartData = _buildChartData(validBills);

    // Chỉ số điện nước từ BILL mới nhất (newNumber)

// Nếu 1 phòng → lấy chỉ số mới nhất của phòng đó
// Nếu nhiều phòng → cộng tổng số đã dùng (used) của tháng hiện tại

    double latestElec = 0.0;
    double latestWater = 0.0;

    if (activeRooms.length <= 1) {
      // 1 phòng: lấy newNumber của bill mới nhất
      if (validBills.isNotEmpty) {
        latestElec = validBills.first.electric.newNumber;
        latestWater = validBills.first.water.newNumber;
      }
    } else {
      // Nhiều phòng: cộng tổng số đã DÙNG (used) tháng hiện tại
      // mỗi phòng lấy bill mới nhất của phòng đó
      for (final room in activeRooms) {
        final roomBills = validBills
            .where((b) => b.idRoom.id == room.bhRoomId)
            .toList(); // đã sort desc
        if (roomBills.isNotEmpty) {
          latestElec += roomBills.first.electric.used;
          latestWater += roomBills.first.water.used;
        }
      }
    }
    final String roomTitle;
    if (roomPvd.loading) {
      roomTitle = 'Đang tải...';
    } else if (rooms.isEmpty) {
      roomTitle = 'Chưa có phòng';
    } else if (activeRooms.isEmpty) {
      roomTitle = '${rooms.length} phòng · Chờ xác nhận';
    } else if (activeRooms.length == 1) {
      final r = activeRooms.first;
      final bh = roomPvd.boardingHouseFor(r.bhId);
      roomTitle = '${bh?.bhName ?? 'Dãy trọ'} - Phòng ${r.bhRoomNumber}';
    } else {
      roomTitle = '${activeRooms.length} phòng đang thuê';
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160, floating: false, pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Xin chào, ${user.name.split(' ').last}! 👋',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(roomTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            title:
                const Text('Tổng quan', style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              const NotificationBell(),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (roomPvd.loading)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()))
                else if (rooms.isEmpty)
                  _buildNoRoomBanner()
                else if (activeRooms.isEmpty)
                  _buildWaitingBanner(rooms.first)
                else ...[
                  // Danh sách phòng scroll ngang (nếu >1)
                  if (activeRooms.length > 1) ...[
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: activeRooms.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            _buildRoomChip(activeRooms[i], roomPvd),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildRoomSummaryCard(activeRooms.first,
                        roomPvd.boardingHouseFor(activeRooms.first.bhId)),
                    const SizedBox(height: 16),
                  ],
                  // Chỉ số điện nước từ bill
                  Row(children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.bolt,
                        iconColor: AppTheme.elecColor,
                        label: activeRooms.length > 1
                            ? 'Điện dùng (tổng)'
                            : 'Chỉ số điện',
                        value: activeRooms.length > 1
                            ? '${latestElec.toStringAsFixed(1)} kWh'
                            : '${latestElec.toStringAsFixed(1)} kWh',
                        trend: _calcTrend(validBills, isElec: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        icon: Icons.water_drop,
                        iconColor: AppTheme.waterColor,
                        label: activeRooms.length > 1
                            ? 'Nước dùng (tổng)'
                            : 'Chỉ số nước',
                        value: '${latestWater.toStringAsFixed(1)} m³',
                        trend: _calcTrend(validBills, isElec: false),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),
                ],
                // Hóa đơn cần xử lý
                if (billPvd.loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator()))
                else if (active.isNotEmpty) ...[
                  const Text('Hóa đơn cần xử lý',
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
                                  builder: (_) =>
                                      BillDetailScreen(bill: bill))),
                          child: UnpaidCard(bill: bill, fmt: fmt),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                // Biểu đồ
                if (validBills.isNotEmpty) ...[
                  Text(
                      activeRooms.length > 1
                          ? 'Biểu đồ chi phí điện nước · Tổng tất cả phòng'
                          : 'Biểu đồ chi phí điện nước',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  TotalChart(data: chartData),
                  const SizedBox(height: 16),
                  ElecWaterChart(data: chartData),
                  const SizedBox(height: 30),

                  // Biểu đồ riêng từng phòng (chỉ hiện khi user thuê > 1 phòng)
                  if (activeRooms.length > 1)
                    ...activeRooms.expand((room) {
                      final bh = roomPvd.boardingHouseFor(room.bhId);
                      final roomChartData =
                          _buildChartData(billPvd.bills, roomId: room.bhRoomId);
                      return <Widget>[
                        Row(children: [
                          Container(
                            width: 6,
                            height: 16,
                            decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(3)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '${bh?.bhName ?? 'Dãy trọ'} - Phòng ${room.bhRoomNumber}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 12),
                        TotalChart(data: roomChartData),
                        const SizedBox(height: 16),
                        ElecWaterChart(data: roomChartData),
                        const SizedBox(height: 30),
                      ];
                    }),
                ] else if (!billPvd.loading && activeRooms.isNotEmpty) ...[
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

  Widget _buildRoomChip(BhRoomModel room, BhRoomProviderUser pvd) {
    final bh = pvd.boardingHouseFor(room.bhId);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(bh?.bhName ?? 'Dãy trọ',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text('P. ${room.bhRoomNumber}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.bolt, size: 12, color: AppTheme.elecColor),
              Text(' ${room.bhRoomLastElec.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 8),
              const Icon(Icons.water_drop,
                  size: 12, color: AppTheme.waterColor),
              Text(' ${room.bhRoomLastWater.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11)),
            ]),
          ]),
    );
  }

  Widget _buildNoRoomBanner() => Container(
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
            ]),
        child: const Column(children: [
          Icon(Icons.home_outlined, size: 52, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Chưa có phòng trọ',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 6),
          Text('Vào tab "Phòng" để nhập mã và tham gia phòng trọ',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
      );

  Widget _buildWaitingBanner(BhRoomModel room) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Color(0xFFF59E0B), size: 28)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Phòng ${room.bhRoomNumber} · Chờ xác nhận',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF92400E))),
                const SizedBox(height: 4),
                const Text('Chủ trọ đang xét duyệt yêu cầu của bạn',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
              ])),
        ]),
      );

  Widget _buildRoomSummaryCard(BhRoomModel room, dynamic bh) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.home, color: AppTheme.primary, size: 28)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(bh?.bhName ?? 'Dãy trọ',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text('Phòng ${room.bhRoomNumber}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
                if (bh != null && bh.bhAddress.isNotEmpty)
                  Text(bh.bhAddress,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Đang thuê',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor))),
        ]),
      );

  Widget _buildNoInvoiceBanner() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ]),
        child: const Column(children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textHint),
          SizedBox(height: 10),
          Text('Chưa có hóa đơn nào',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ]),
      );

  List<Map<String, double>> _buildChartData(
    List<BillModel> bills, {
    String? roomId,
  }) {
    final now = DateTime.now();
    final source = bills.where((b) {
      if (b.billStatus == BillStatus.cancelled) return false;
      if (roomId != null && b.idRoom.id != roomId) return false;
      return true;
    }).toList();
    return List.generate(5, (i) {
      final m = DateTime(now.year, now.month - (4 - i));
      final monthKey = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      final matched = source.where((b) => b.month == monthKey);
      return {
        'month': m.month.toDouble(),
        'elec': matched.fold<double>(0, (s, b) => s + b.electric.total),
        'water': matched.fold<double>(0, (s, b) => s + b.water.total),
      };
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
