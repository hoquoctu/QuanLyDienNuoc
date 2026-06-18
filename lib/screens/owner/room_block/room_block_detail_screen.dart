import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/owner/boarding_house_provider.dart';
import '../../../models/boarding_house_model.dart';
import '../../../providers/auth_provider.dart'; // import auth để lấy ownerName
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';
import '../../../widgets/owner/boarding_house/detail_room/AddRoomsSheetState.dart';
import '../../../widgets/owner/boarding_house/detail_room/BhHeader.dart';
import 'package:quanlydiennc_app/widgets/owner/boarding_house/detail_room/RoomTile.dart';

class RoomBlockDetailScreen extends StatefulWidget {
  final String blockId;
  const RoomBlockDetailScreen({super.key, required this.blockId});
  @override
  State<RoomBlockDetailScreen> createState() => _RoomBlockDetailScreenState();
}

class _RoomBlockDetailScreenState extends State<RoomBlockDetailScreen> {
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    final bh = _getBh(context);
    _nameCtrl = TextEditingController(text: bh?.bhName ?? '');
    _addrCtrl = TextEditingController(text: bh?.bhAddress ?? '');
    _descCtrl = TextEditingController(text: bh?.bhDescription ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  BoardingHouseModel? _getBh(BuildContext context) {
    final list = context.read<BoardingHouseProvider>().bhList;
    try {
      return list.firstWhere((b) => b.bhId == widget.blockId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardingHouseProvider>();
    final bh = provider.bhList
        .cast<BoardingHouseModel?>()
        .firstWhere((b) => b?.bhId == widget.blockId, orElse: () => null);

    if (bh == null) return const SizedBox();

    final rooms = provider.roomsOf(widget.blockId);

    // Lấy thông tin owner từ auth provider
    // Nếu m dùng tên provider khác thì sửa lại dòng này
    final user = context.read<AuthProvider>().currentUser;
    final ownerId = user?.uid ?? '';
    final ownerName = user?.name ?? 'Chủ trọ';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: _editMode ? const Text('Chỉnh sửa dãy trọ') : Text(bh.bhName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editMode = true),
            )
          else
            TextButton(
              onPressed: () => _saveEdit(context, bh),
              child: const Text('Lưu',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          BhHeader(
            bh: bh,
            rooms: rooms,
            editMode: _editMode,
            nameCtrl: _nameCtrl,
            addrCtrl: _addrCtrl,
            descCtrl: _descCtrl,
          ),

          // ── Room list header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách phòng',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.textPrimary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm phòng'),
                  onPressed: () => _showAddRoomsSheet(context),
                ),
              ],
            ),
          ),

          // ── Rooms ────────────────────────────────────────────────────────
          Expanded(
            child: rooms.isEmpty
                ? const Center(
                    child: Text('Chưa có phòng nào',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => RoomTile(
                      room: rooms[i],
                      bhName: bh.bhName,
                      ownerId: ownerId,
                      ownerName: ownerName,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Lưu chỉnh sửa ──────────────────────────────────────────────────────
  Future<void> _saveEdit(BuildContext context, BoardingHouseModel bh) async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận thay đổi',
      subtitle: 'Cập nhật thông tin dãy trọ "${_nameCtrl.text}"?',
      confirmLabel: 'Xác nhận',
    );
    if (ok == true && mounted) {
      final err = await context.read<BoardingHouseProvider>().updateBh(
            widget.blockId,
            name: _nameCtrl.text,
            address: _addrCtrl.text,
            description: _descCtrl.text,
          );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      } else if (mounted) {
        setState(() => _editMode = false);
      }
    }
  }

  // ── Sheet thêm phòng hàng loạt ──────────────────────────────────────────
  void _showAddRoomsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRoomsSheet(bhId: widget.blockId),
    );
  }
}
