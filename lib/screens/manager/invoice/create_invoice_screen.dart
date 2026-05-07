import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/room_block_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bottom_sheet_confirm.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});
  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  String? _selectedBlockId;
  String? _selectedRoomId;
  final _currElecCtrl = TextEditingController();
  final _currWaterCtrl = TextEditingController();
  String? _imagePath;
  bool _submitting = false;
  String? _successMsg;

  @override
  void dispose() {
    _currElecCtrl.dispose();
    _currWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera);
    if (xfile != null) setState(() => _imagePath = xfile.path);
  }

  Future<void> _submit() async {
    if (_selectedBlockId == null || _selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn dãy và phòng')));
      return;
    }
    final room = context.read<RoomProvider>().getById(_selectedRoomId!);
    if (room == null || room.tenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phòng chưa có người thuê')));
      return;
    }
    final currElec = double.tryParse(_currElecCtrl.text);
    final currWater = double.tryParse(_currWaterCtrl.text);
    if (currElec == null || currWater == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đủ chỉ số điện nước')));
      return;
    }
    if (currElec < room.lastElecReading || currWater < room.lastWaterReading) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Chỉ số mới không được nhỏ hơn chỉ số cũ')));
      return;
    }

    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận tạo hóa đơn',
      subtitle: 'Tạo hóa đơn tháng này cho phòng ${room.name}?',
      confirmLabel: 'Tạo hóa đơn',
    );
    if (ok != true || !mounted) return;

    setState(() => _submitting = true);
    final block = context.read<RoomBlockProvider>().getById(_selectedBlockId!)!;
    final invPvd = context.read<InvoiceProvider>();
    await invPvd.createInvoice(
      roomId: room.id,
      roomName: room.name,
      blockId: block.id,
      blockName: block.name,
      blockAddress: block.address,
      tenantId: room.tenantId!,
      tenantName: room.tenantName!,
      prevElec: room.lastElecReading,
      currElec: currElec,
      prevWater: room.lastWaterReading,
      currWater: currWater,
      imagePath: _imagePath,
    );
    await context.read<RoomProvider>().updateLastReadings(
        room.id, currElec, currWater);

    setState(() {
      _submitting = false;
      _successMsg =
          'Đã tạo hóa đơn cho phòng ${room.name}!';
      _selectedRoomId = null;
      _currElecCtrl.clear();
      _currWaterCtrl.clear();
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final blocks = context.read<RoomBlockProvider>().blocksForManager(user.id);
    final invPvd = context.watch<InvoiceProvider>();
    final fmt = NumberFormat('#,###', 'vi_VN');

    List<RoomModel> rooms = [];
    RoomModel? selectedRoom;
    if (_selectedBlockId != null) {
      rooms = context
          .watch<RoomProvider>()
          .roomsInBlock(_selectedBlockId!)
          .where((r) => r.status == RoomStatus.rented)
          .toList();
    }
    if (_selectedRoomId != null) {
      selectedRoom =
          context.read<RoomProvider>().getById(_selectedRoomId!);
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Tạo hóa đơn điện nước')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_successMsg != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_successMsg!,
                          style: const TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600))),
                ]),
              ),

            // Step 1: Select block
            _SectionLabel(
                number: '1', label: 'Chọn dãy trọ'),
            const SizedBox(height: 8),
            if (blocks.length == 1)
              _SelectionCard(
                icon: Icons.apartment,
                title: blocks.first.name,
                subtitle: blocks.first.address,
                selected: true,
                onTap: () =>
                    setState(() => _selectedBlockId = blocks.first.id),
              )
            else
              ...blocks.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SelectionCard(
                      icon: Icons.apartment,
                      title: b.name,
                      subtitle: b.address,
                      selected: _selectedBlockId == b.id,
                      onTap: () => setState(() {
                        _selectedBlockId = b.id;
                        _selectedRoomId = null;
                      }),
                    ),
                  )),

            // Step 2: Select room
            if (_selectedBlockId != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(number: '2', label: 'Chọn phòng'),
              const SizedBox(height: 8),
              rooms.isEmpty
                  ? const Text('Không có phòng nào đang cho thuê',
                      style: TextStyle(color: AppTheme.textSecondary))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rooms.map((r) {
                        final selected = _selectedRoomId == r.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRoomId = r.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(r.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.textPrimary)),
                                Text(
                                  r.tenantName ?? '',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: selected
                                          ? Colors.white70
                                          : AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],

            // Step 3: Enter readings
            if (selectedRoom != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(number: '3', label: 'Nhập chỉ số'),
              const SizedBox(height: 12),

              // Electricity
              _ReadingInput(
                label: '⚡ Điện (kWh)',
                prevValue: selectedRoom.lastElecReading,
                controller: _currElecCtrl,
                color: AppTheme.elecColor,
                unitPrice: invPvd.elecPrice,
                fmt: fmt,
              ),
              const SizedBox(height: 12),
              _ReadingInput(
                label: '💧 Nước (m³)',
                prevValue: selectedRoom.lastWaterReading,
                controller: _currWaterCtrl,
                color: AppTheme.waterColor,
                unitPrice: invPvd.waterPrice,
                fmt: fmt,
              ),

              // Image capture
              const SizedBox(height: 20),
              _SectionLabel(number: '4', label: 'Chụp ảnh đồng hồ'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _imagePath != null
                          ? AppTheme.successColor
                          : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined,
                                color: AppTheme.textHint, size: 36),
                            SizedBox(height: 8),
                            Text('Chụp ảnh đồng hồ đo',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                            Text('(Không bắt buộc)',
                                style: TextStyle(
                                    color: AppTheme.textHint,
                                    fontSize: 11)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),
              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Tạo hóa đơn'),
                    ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String number;
  final String label;
  const _SectionLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textHint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ReadingInput extends StatefulWidget {
  final String label;
  final double prevValue;
  final TextEditingController controller;
  final Color color;
  final double unitPrice;
  final NumberFormat fmt;
  const _ReadingInput({
    required this.label,
    required this.prevValue,
    required this.controller,
    required this.color,
    required this.unitPrice,
    required this.fmt,
  });
  @override
  State<_ReadingInput> createState() => _ReadingInputState();
}

class _ReadingInputState extends State<_ReadingInput> {
  double? _calc;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  void _update() {
    final v = double.tryParse(widget.controller.text);
    setState(() => _calc =
        v != null && v > widget.prevValue ? (v - widget.prevValue) * widget.unitPrice : null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chỉ số cũ',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                    Text(
                      widget.fmt.format(widget.prevValue),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward,
                  color: AppTheme.textHint, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chỉ số mới',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: widget.color, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_calc != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Spacer(),
              Text(
                '≈ ${widget.fmt.format(_calc)}đ',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                    fontSize: 14),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}
