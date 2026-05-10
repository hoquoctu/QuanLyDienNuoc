import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_block_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';
import '../../../widgets/status_badge.dart';
import '../room/room_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    final block = context.read<RoomBlockProvider>().getById(widget.blockId)!;
    _nameCtrl = TextEditingController(text: block.name);
    _addrCtrl = TextEditingController(text: block.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = context.watch<RoomBlockProvider>().getById(widget.blockId);
    if (block == null) return const SizedBox();
    final rooms = context.watch<RoomProvider>().roomsInBlock(widget.blockId);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: _editMode ? const Text('Chỉnh sửa dãy trọ') : Text(block.name),
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
              onPressed: _saveEdit,
              child: const Text('Lưu',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
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
            child: _editMode
                ? Column(
                    children: [
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          labelText: 'Tên dãy trọ',
                          labelStyle: TextStyle(color: Colors.white70),
                          fillColor: Colors.white24,
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addrCtrl,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ',
                          labelStyle: TextStyle(color: Colors.white60),
                          fillColor: Colors.white24,
                          filled: true,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        block.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        block.address,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                              label: '${rooms.length}', desc: 'Tổng phòng'),
                          const SizedBox(width: 20),
                          _StatChip(
                              label:
                                  '${rooms.where((r) => r.status == RoomStatus.rented).length}',
                              desc: 'Đang thuê'),
                          const SizedBox(width: 20),
                          _StatChip(
                              label:
                                  '${rooms.where((r) => r.status == RoomStatus.empty).length}',
                              desc: 'Trống'),
                        ],
                      ),
                    ],
                  ),
          ),

          // Room list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách phòng',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm phòng'),
                  onPressed: () => _showAddRoomsSheet(context, widget.blockId),
                ),
              ],
            ),
          ),

          // Rooms
          Expanded(
            child: rooms.isEmpty
                ? const Center(
                    child: Text('Chưa có phòng nào',
                        style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) =>
                        _RoomTile(room: rooms[i], blockId: widget.blockId),
                  ),
          ),
        ],
      ),
    );
  }

  void _saveEdit() async {
    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận thay đổi',
      subtitle: 'Cập nhật thông tin dãy trọ "${_nameCtrl.text}"?',
      confirmLabel: 'Xác nhận',
    );
    if (ok == true && mounted) {
      final err = await context.read<RoomBlockProvider>().updateBlock(
            widget.blockId,
            name: _nameCtrl.text,
            address: _addrCtrl.text,
          );
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      } else if (mounted) {
        setState(() => _editMode = false);
      }
    }
  }

  void _showAddRoomsSheet(BuildContext context, String blockId) {
    final prefixCtrl = TextEditingController(text: 'B1-');
    final startCtrl = TextEditingController(text: '1');
    final endCtrl = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
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
              const Text('Thêm phòng hàng loạt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Hệ thống sẽ tự tạo phòng từ: B1-01, B1-02...',
                  style:
                      TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              TextField(
                controller: prefixCtrl,
                decoration:
                    const InputDecoration(labelText: 'Tiền tố (prefix)'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Từ số'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Đến số'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final start = int.tryParse(startCtrl.text) ?? 1;
                  final end = int.tryParse(endCtrl.text) ?? 1;
                  if (end < start) return;
                  await context.read<RoomProvider>().addRooms(
                        blockId,
                        prefixCtrl.text,
                        start,
                        end,
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Tạo phòng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomTile extends StatefulWidget {
  final RoomModel room;
  final String blockId;
  const _RoomTile({required this.room, required this.blockId});
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
    final room = widget.room;
    if (room.joinCodeExpiry != null) {
      final diff = room.joinCodeExpiry!.difference(DateTime.now());
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
          )
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (room.status == RoomStatus.rented) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomDetailScreen(roomId: room.id),
                  ),
                );
              } else {
                setState(() => _expanded = !_expanded);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor(room.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        room.name.split('-').last,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _statusColor(room.status),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        if (room.tenantName != null)
                          Text(room.tenantName!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  StatusBadge.room(room.status),
                  const SizedBox(width: 8),
                  Icon(
                    room.status == RoomStatus.rented
                        ? Icons.chevron_right
                        : (_expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                    color: AppTheme.textHint,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded && room.status != RoomStatus.rented)
            _buildExpandedContent(context, room),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, RoomModel room) {
    final roomPvd = context.read<RoomProvider>();

    if (room.status == RoomStatus.empty) {
      return _EmptyRoomExpanded(
        room: room,
        remaining: _remaining,
        onGenCode: () async {
          await roomPvd.generateJoinCode(room.id);
          _startTimer();
        },
      );
    }

    if (room.status == RoomStatus.pending) {
      return _PendingRoomExpanded(
        room: room,
        onConfirm: () async {
          final ok = await showConfirmSheet<bool>(
            context,
            title: 'Xác nhận cho thuê',
            subtitle: 'Xác nhận cho ${room.tenantName} vào phòng ${room.name}?',
            confirmLabel: 'Xác nhận cho vào',
          );
          if (ok == true && context.mounted) {
            await roomPvd.confirmTenant(room.id, true);
          }
        },
        onReject: () async {
          final ok = await showConfirmSheet<bool>(
            context,
            title: 'Từ chối',
            subtitle: 'Từ chối yêu cầu của ${room.tenantName}?',
            confirmLabel: 'Từ chối',
            confirmColor: AppTheme.errorColor,
          );
          if (ok == true && context.mounted) {
            await roomPvd.confirmTenant(room.id, false);
          }
        },
      );
    }

    if (room.status == RoomStatus.inactive) {
      return _InactiveRoomExpanded(
        room: room,
        onReactivate: () async {
          final ok = await showConfirmSheet<bool>(
            context,
            title: 'Mở lại phòng',
            subtitle: 'Mở lại phòng ${room.name}?',
            confirmLabel: 'Mở lại',
          );
          if (ok == true && context.mounted) {
            await roomPvd.reactivateRoom(room.id);
          }
        },
        onDelete: () async {
          if (room.everRented) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Phòng đã từng có người thuê, không thể xóa!')),
            );
            return;
          }
          final ok = await showConfirmSheet<bool>(
            context,
            title: 'Xóa vĩnh viễn',
            subtitle: 'Xóa phòng ${room.name} vĩnh viễn?',
            confirmLabel: 'Xóa vĩnh viễn',
            confirmColor: AppTheme.errorColor,
          );
          if (ok == true && context.mounted) {
            await roomPvd.deleteRoomPermanent(room.id);
          }
        },
      );
    }

    return const SizedBox();
  }

  Color _statusColor(RoomStatus s) {
    switch (s) {
      case RoomStatus.rented:
        return AppTheme.successColor;
      case RoomStatus.pending:
        return AppTheme.primary;
      case RoomStatus.empty:
        return AppTheme.textSecondary;
      case RoomStatus.inactive:
        return AppTheme.errorColor;
    }
  }
}

class _EmptyRoomExpanded extends StatelessWidget {
  final RoomModel room;
  final Duration remaining;
  final VoidCallback onGenCode;
  const _EmptyRoomExpanded(
      {required this.room, required this.remaining, required this.onGenCode});

  @override
  Widget build(BuildContext context) {
    final hasCode = room.isJoinCodeValid;
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
                    Clipboard.setData(ClipboardData(text: room.joinCode!));
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
                          room.joinCode!,
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
  final RoomModel room;
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
              Text(room.tenantName ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
  final RoomModel room;
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
          if (!room.everRented) ...[
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_forever, size: 16),
                label: const Text('Xóa vĩnh viễn'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
