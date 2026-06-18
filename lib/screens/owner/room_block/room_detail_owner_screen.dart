import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/providers/owner/room_review_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/room_review_widgets.dart';

/// Màn hình detail phòng dành cho OWNER
/// Tab 0: Thông tin phòng (chỉ số điện nước, trạng thái, tenant)
/// Tab 1: Đánh giá (chỉ xem, không edit)
class RoomDetailOwnerScreen extends StatefulWidget {
  final BhRoomModel room;
  final String bhName;

  const RoomDetailOwnerScreen({
    super.key,
    required this.room,
    required this.bhName,
  });

  @override
  State<RoomDetailOwnerScreen> createState() => _RoomDetailOwnerScreenState();
}

class _RoomDetailOwnerScreenState extends State<RoomDetailOwnerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // owner side → tenantId = null
      context.read<RoomReviewProvider>().init(widget.room.bhRoomId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<RoomReviewProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phòng ${widget.room.bhRoomNumber}'),
            Text(
              widget.bhName,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'Thông tin'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đánh giá'),
                  if (reviewProvider.reviews.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${reviewProvider.reviews.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab 0: Thông tin phòng ────────────────────────────────────────
          _RoomInfoTab(room: widget.room),

          // ── Tab 1: Đánh giá ───────────────────────────────────────────────
          _ReviewsTab(provider: reviewProvider),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab thông tin phòng
// ═══════════════════════════════════════════════════════════════════════════

class _RoomInfoTab extends StatelessWidget {
  final BhRoomModel room;
  const _RoomInfoTab({required this.room});

  @override
  Widget build(BuildContext context) {
    final isOccupied = room.bhRoomStatus == BhRoomStatus.occupied;
    final isWaiting = room.bhRoomStatus == BhRoomStatus.waiting;
    final isAvailable = room.bhRoomStatus == BhRoomStatus.available;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isOccupied) {
      statusColor = AppTheme.successColor;
      statusLabel = 'Đang thuê';
      statusIcon = Icons.check_circle_outline;
    } else if (isWaiting) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Chờ xác nhận';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isAvailable) {
      statusColor = AppTheme.primary;
      statusLabel = 'Trống';
      statusIcon = Icons.door_front_door_outlined;
    } else {
      statusColor = AppTheme.textSecondary;
      statusLabel = 'Không hoạt động';
      statusIcon = Icons.block_outlined;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trạng thái ──────────────────────────────────────────────────
          _InfoCard(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Người thuê ──────────────────────────────────────────────────
          if (room.bhRoomTenantName != null) ...[
            _InfoCard(
              label: 'Người thuê hiện tại',
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        room.bhRoomTenantName!.isNotEmpty
                            ? room.bhRoomTenantName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      room.bhRoomTenantName!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Chỉ số điện nước ────────────────────────────────────────────
          _InfoCard(
            label: 'Chỉ số điện nước',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.bolt,
                      iconColor: AppTheme.elecColor,
                      label: 'Điện',
                      value: '${room.bhRoomLastElec.toStringAsFixed(1)} kWh',
                    ),
                  ),
                  Container(
                      width: 0.5,
                      height: 40,
                      color: AppTheme.textHint.withOpacity(0.2)),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.water_drop,
                      iconColor: AppTheme.waterColor,
                      label: 'Nước',
                      value: '${room.bhRoomLastWater.toStringAsFixed(1)} m³',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Thời gian cập nhật ──────────────────────────────────────────
          if (room.bhRoomUpdateTime != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.update, size: 12, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  'Cập nhật: ${_formatDate(room.bhRoomUpdateTime!)}',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab đánh giá (owner chỉ xem)
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewsTab extends StatelessWidget {
  final RoomReviewProvider provider;
  const _ReviewsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (provider.reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 52, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text(
              'Chưa có đánh giá nào',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary),
            ),
            SizedBox(height: 6),
            Text(
              'Đánh giá sẽ xuất hiện khi người thuê gửi',
              style: TextStyle(fontSize: 13, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tổng quan rating ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: RatingsSummaryBar(
              average: provider.averageRating,
              count: provider.reviews.length,
            ),
          ),
          const SizedBox(height: 16),

          // ── Danh sách reviews ────────────────────────────────────────────
          const Text(
            'Tất cả đánh giá',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReviewCard(
                review: r,
                isOwner: true, // owner không có nút edit
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const _InfoCard({this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
