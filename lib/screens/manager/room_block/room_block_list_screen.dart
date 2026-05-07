import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_block_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';
import 'room_block_detail_screen.dart';

class RoomBlockListScreen extends StatelessWidget {
  const RoomBlockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final blockProvider = context.watch<RoomBlockProvider>();
    final blocks = blockProvider.blocksForManager(user.id);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Dãy trọ của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.primary,
            onPressed: () => _showAddBlockSheet(context, user.id),
          ),
        ],
      ),
      body: blocks.isEmpty
          ? _buildEmpty(context, user.id)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: blocks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final block = blocks[i];
                final rooms = context
                    .watch<RoomProvider>()
                    .roomsInBlock(block.id);
                final rented =
                    rooms.where((r) => r.status.name == 'rented').length;
                return _BlockCard(
                  name: block.name,
                  address: block.address,
                  totalRooms: rooms.length,
                  rentedRooms: rented,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RoomBlockDetailScreen(blockId: block.id),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, block.id,
                      block.name, rooms.any((r) => r.status.name == 'rented')),
                );
              },
            ),
    );
  }

  void _showAddBlockSheet(BuildContext context, String managerId) {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thêm dãy trọ mới',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên dãy trọ',
                  hintText: 'VD: Dãy Trọ Bình Minh',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addrCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  hintText: 'VD: 123 Đường ABC, Quận 9',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final err = await context
                      .read<RoomBlockProvider>()
                      .addBlock(
                        managerId: managerId,
                        name: nameCtrl.text,
                        address: addrCtrl.text,
                      );
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err)),
                    );
                  } else if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Thêm dãy trọ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String blockId, String name,
      bool hasActiveTenants) async {
    if (hasActiveTenants) {
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
      subtitle: 'Bạn có chắc muốn xóa "$name"?',
      confirmLabel: 'Xóa',
      confirmColor: AppTheme.errorColor,
    );
    if (ok == true && context.mounted) {
      await context.read<RoomBlockProvider>().deleteBlock(blockId);
    }
  }

  Widget _buildEmpty(BuildContext context, String managerId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment_outlined,
              size: 72, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text('Chưa có dãy trọ nào',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddBlockSheet(context, managerId),
            icon: const Icon(Icons.add),
            label: const Text('Thêm dãy trọ đầu tiên'),
          ),
        ],
      ),
    );
  }
}

class _BlockCard extends StatelessWidget {
  final String name;
  final String address;
  final int totalRooms;
  final int rentedRooms;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _BlockCard({
    required this.name,
    required this.address,
    required this.totalRooms,
    required this.rentedRooms,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.apartment,
                  color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(address,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.door_front_door_outlined,
                          label: '$totalRooms phòng'),
                      const SizedBox(width: 8),
                      _InfoChip(
                          icon: Icons.people_outline,
                          label: '$rentedRooms đã thuê',
                          color: AppTheme.successColor),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.errorColor, size: 20),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      this.color = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
