import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/boarding_house_model.dart';
import '../../../models/bh_room_model.dart';
import '../../../providers/boarding_house_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';
import '../../../theme/StatusBadge.dart';

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
          _BhHeader(
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
                    itemBuilder: (ctx, i) => _RoomTile(room: rooms[i]),
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
      builder: (_) => _AddRoomsSheet(bhId: widget.blockId),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER DÃY TRỌ
// ═══════════════════════════════════════════════════════════════════════════

class _BhHeader extends StatelessWidget {
  final BoardingHouseModel bh;
  final List<BhRoomModel> rooms;
  final bool editMode;
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final TextEditingController descCtrl;

  const _BhHeader({
    required this.bh,
    required this.rooms,
    required this.editMode,
    required this.nameCtrl,
    required this.addrCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final occupiedCount =
        rooms.where((r) => r.bhRoomStatus == BhRoomStatus.occupied).length;
    final emptyCount =
        rooms.where((r) => r.bhRoomStatus == BhRoomStatus.empty).length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: editMode
          ? _BhEditForm(
              nameCtrl: nameCtrl,
              addrCtrl: addrCtrl,
              descCtrl: descCtrl,
            )
          : _BhInfoDisplay(
              bh: bh,
              totalRooms: rooms.length,
              occupiedCount: occupiedCount,
              emptyCount: emptyCount,
            ),
    );
  }
}

class _BhEditForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final TextEditingController descCtrl;

  const _BhEditForm({
    required this.nameCtrl,
    required this.addrCtrl,
    required this.descCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameCtrl,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            labelText: 'Tên dãy trọ',
            labelStyle: TextStyle(color: Colors.white70),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: addrCtrl,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ',
            labelStyle: TextStyle(color: Colors.white60),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: descCtrl,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            labelStyle: TextStyle(color: Colors.white60),
            fillColor: Colors.white24,
            filled: true,
          ),
        ),
      ],
    );
  }
}

class _BhInfoDisplay extends StatelessWidget {
  final BoardingHouseModel bh;
  final int totalRooms;
  final int occupiedCount;
  final int emptyCount;

  const _BhInfoDisplay({
    required this.bh,
    required this.totalRooms,
    required this.occupiedCount,
    required this.emptyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          bh.bhName,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          bh.bhAddress,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        if (bh.bhDescription.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            bh.bhDescription,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(label: '$totalRooms', desc: 'Tổng phòng'),
            const SizedBox(width: 20),
            _StatChip(label: '$occupiedCount', desc: 'Đang thuê'),
            const SizedBox(width: 20),
            _StatChip(label: '$emptyCount', desc: 'Trống'),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHEET THÊM PHÒNG HÀNG LOẠT — fix bàn phím thật
// ═══════════════════════════════════════════════════════════════════════════

class _AddRoomsSheet extends StatefulWidget {
  final String bhId;
  const _AddRoomsSheet({required this.bhId});

  @override
  State<_AddRoomsSheet> createState() => _AddRoomsSheetState();
}

class _AddRoomsSheetState extends State<_AddRoomsSheet> {
  final _prefixCtrl = TextEditingController(text: 'P');
  final _startCtrl = TextEditingController(text: '1');
  final _endCtrl = TextEditingController(text: '10');
  bool _saving = false;

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final start = int.tryParse(_startCtrl.text) ?? 1;
    final end = int.tryParse(_endCtrl.text) ?? 1;
    if (end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số cuối phải lớn hơn số đầu')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<BoardingHouseProvider>();
    String? lastErr;

    for (int i = start; i <= end; i++) {
      final roomNumber = '${_prefixCtrl.text}${i.toString().padLeft(2, '0')}';
      lastErr =
          await provider.addRoom(bhId: widget.bhId, roomNumber: roomNumber);
      if (lastErr != null) break;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (lastErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(lastErr)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Thêm phòng hàng loạt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hệ thống sẽ tự tạo: P01, P02, P03...',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _prefixCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tiền tố (prefix)',
                hintText: 'VD: P, B1-, T',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Từ số'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Đến số'),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tạo phòng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOM TILE
// ═══════════════════════════════════════════════════════════════════════════

class _RoomTile extends StatefulWidget {
  final BhRoomModel room;
  const _RoomTile({required this.room});

  @override
  State<_RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<_RoomTile> {
  bool _expanded = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final expiry = widget.room.bhRoomJoinCodeExpiry;
    if (expiry != null) {
      final diff = expiry.difference(DateTime.now());
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // TODO: navigate to RoomDetailScreen khi làm trang đó
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _RoomNumberBox(room: room),
                  const SizedBox(width: 12),
                  Expanded(child: _RoomTileInfo(room: room)),
                  StatusBadge.bhRoom(room.bhRoomStatus),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _buildExpandedContent(context, room),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, BhRoomModel room) {
    switch (room.bhRoomStatus) {
      case BhRoomStatus.empty:
        return _EmptyRoomExpanded(
          room: room,
          remaining: _remaining,
          onGenCode: () {
            // TODO: generate join code khi làm feature này
            _startTimer();
          },
        );
      case BhRoomStatus.pending:
        return _PendingRoomExpanded(
          room: room,
          onConfirm: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Xác nhận cho thuê',
              subtitle:
                  'Xác nhận cho ${room.bhRoomTenantName} vào phòng ${room.bhRoomNumber}?',
              confirmLabel: 'Xác nhận',
            );
            if (ok == true && context.mounted) {
              // TODO: confirm tenant
            }
          },
          onReject: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Từ chối',
              subtitle: 'Từ chối yêu cầu của ${room.bhRoomTenantName}?',
              confirmLabel: 'Từ chối',
              confirmColor: AppTheme.errorColor,
            );
            if (ok == true && context.mounted) {
              // TODO: reject tenant
            }
          },
        );
      case BhRoomStatus.inactive:
        return _InactiveRoomExpanded(
          room: room,
          onReactivate: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Mở lại phòng',
              subtitle: 'Mở lại phòng ${room.bhRoomNumber}?',
              confirmLabel: 'Mở lại',
            );
            if (ok == true && context.mounted) {
              // TODO: reactivate room
            }
          },
          onDelete: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Xóa vĩnh viễn',
              subtitle: 'Xóa phòng ${room.bhRoomNumber} vĩnh viễn?',
              confirmLabel: 'Xóa vĩnh viễn',
              confirmColor: AppTheme.errorColor,
            );
            if (ok == true && context.mounted) {
              await context
                  .read<BoardingHouseProvider>()
                  .deleteRoom(room.bhRoomId, room.bhRoomStatus);
            }
          },
        );
      default:
        return const SizedBox();
    }
  }
}

class _RoomNumberBox extends StatelessWidget {
  final BhRoomModel room;
  const _RoomNumberBox({required this.room});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(room.bhRoomStatus);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          room.bhRoomNumber.length > 4
              ? room.bhRoomNumber.substring(room.bhRoomNumber.length - 3)
              : room.bhRoomNumber,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _statusColor(BhRoomStatus s) {
    switch (s) {
      case BhRoomStatus.occupied:
        return AppTheme.successColor;
      case BhRoomStatus.pending:
        return AppTheme.primary;
      case BhRoomStatus.empty:
        return AppTheme.textSecondary;
      case BhRoomStatus.inactive:
        return AppTheme.errorColor;
    }
  }
}

class _RoomTileInfo extends StatelessWidget {
  final BhRoomModel room;
  const _RoomTileInfo({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.bhRoomNumber,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        if (room.bhRoomTenantName != null)
          Text(
            room.bhRoomTenantName!,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPANDED STATES
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final Duration remaining;
  final VoidCallback onGenCode;
  const _EmptyRoomExpanded(
      {required this.room, required this.remaining, required this.onGenCode});

  @override
  Widget build(BuildContext context) {
    final hasCode = room.isBhRoomJoinCodeValid;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: hasCode
          ? Column(
              children: [
                const Text('Mã tham gia phòng',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: room.bhRoomJoinCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          room.bhRoomJoinCode!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy,
                            size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text(
                      'Hết hạn sau: ${_fmt(remaining)}',
                      style: const TextStyle(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                const Text('Phòng chưa có người thuê',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onGenCode,
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Tạo mã tham gia'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40)),
                ),
              ],
            ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PendingRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  const _PendingRoomExpanded(
      {required this.room, required this.onConfirm, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Yêu cầu tham gia',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                room.bhRoomTenantName ?? 'Người dùng',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor),
                  child: const Text('Chấp nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InactiveRoomExpanded extends StatelessWidget {
  final BhRoomModel room;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  const _InactiveRoomExpanded(
      {required this.room, required this.onReactivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReactivate,
              icon: const Icon(Icons.lock_open_outlined, size: 16),
              label: const Text('Mở lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.successColor,
                side: const BorderSide(color: AppTheme.successColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_forever, size: 16),
              label: const Text('Xóa phòng'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String label;
  final String desc;
  const _StatChip({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
