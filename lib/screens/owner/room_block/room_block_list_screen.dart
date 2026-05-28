import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/owner/boarding_house_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/boarding_house_model.dart';
import '../../../models/bh_room_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';
import 'room_block_detail_screen.dart';
import '../../../widgets/owner/boarding_house/AddBhSheet.dart';
import '../../../widgets/owner/boarding_house/BhCard.dart';
import '../../../widgets/owner/boarding_house/BhEmptyState.dart';

class RoomBlockListScreen extends StatelessWidget {
  const RoomBlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ownerUid = context.read<AuthProvider>().currentUser!.uid;
    final provider = context.watch<BoardingHouseProvider>();

    final bhList = provider.bhList;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Dãy trọ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primary,
            onPressed: () {
              _showAddBhSheet(context, ownerUid);
            },
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : bhList.isEmpty
              ? BhEmptyState(
                  onAdd: () => _showAddBhSheet(context, ownerUid),
                )
              : SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: _BhListView(bhList: bhList, ownerUid: ownerUid)),
    );
  }

  void _showAddBhSheet(BuildContext context, String ownerUid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBhSheet(ownerUid: ownerUid),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DANH SÁCH DÃY TRỌ
// ═══════════════════════════════════════════════════════════════════════════

class _BhListView extends StatelessWidget {
  final List<BoardingHouseModel> bhList;
  final String ownerUid;

  const _BhListView({required this.bhList, required this.ownerUid});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardingHouseProvider>();

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: bhList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final bh = bhList[i];
        final rooms = provider.roomsOf(bh.bhId);
        final rentedCount =
            rooms.where((r) => r.bhRoomStatus == BhRoomStatus.occupied).length;

        return BhCard(
          bh: bh,
          totalRooms: rooms.length,
          rentedRooms: rentedCount,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoomBlockDetailScreen(blockId: bh.bhId),
            ),
          ),
          onDelete: () => _confirmDelete(context, bh, rooms),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BoardingHouseModel bh,
    List<BhRoomModel> rooms,
  ) async {
    final hasOccupied =
        rooms.any((r) => r.bhRoomStatus == BhRoomStatus.occupied);

    if (hasOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dãy trọ còn người thuê, không thể xóa!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xóa dãy trọ',
      subtitle: 'Bạn có chắc muốn xóa "${bh.bhName}"?',
      confirmLabel: 'Xóa',
      confirmColor: AppTheme.errorColor,
    );

    if (ok == true && context.mounted) {
      final err = await context.read<BoardingHouseProvider>().deleteBh(bh.bhId);
      if (err != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }
}
