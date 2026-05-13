import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/bh_room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/boarding_house_provider.dart';
import '../../../services/cloudinary_service.dart';

import '../../../services/service_config_service.dart';
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

  String? _electricImagePath;
  String? _waterImagePath;

  bool _submitting = false;

  double _electricPrice = 0.0;
  double _waterPrice = 0.0;

  String? _successMsg;

  @override
  void dispose() {
    _currElecCtrl.dispose();
    _currWaterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServicePrice() async {
    final ownerUid = context.read<AuthProvider>().currentUser!.uid;

    final config = await ServiceConfigService.getPrices(ownerUid);

    setState(() {
      _electricPrice = (config['electricPrice'] ?? 0).toDouble();

      _waterPrice = (config['waterPrice'] ?? 0).toDouble();
    });
  }
  // ───────────────── PICK ELECTRIC IMAGE ─────────────────

  Future<void> _pickElectricImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (file != null) {
      setState(() {
        _electricImagePath = file.path;
      });
    }
  }

  // ───────────────── PICK WATER IMAGE ─────────────────

  Future<void> _pickWaterImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (file != null) {
      setState(() {
        _waterImagePath = file.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadServicePrice();
  }
  // ───────────────── SUBMIT ─────────────────

  Future<void> _submit() async {
    if (_selectedBlockId == null || _selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn dãy và phòng'),
        ),
      );
      return;
    }

    final bhPvd = context.read<BoardingHouseProvider>();

    final room = bhPvd
        .roomsOf(_selectedBlockId!)
        .where((r) => r.bhRoomId == _selectedRoomId)
        .firstOrNull;

    if (room == null || room.bhRoomTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phòng chưa có người thuê'),
        ),
      );
      return;
    }

    final currElec = double.tryParse(
      _currElecCtrl.text,
    );

    final currWater = double.tryParse(
      _currWaterCtrl.text,
    );

    if (currElec == null || currWater == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ chỉ số'),
        ),
      );
      return;
    }

    if (currElec < room.bhRoomLastElec || currWater < room.bhRoomLastWater) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chỉ số mới không được nhỏ hơn chỉ số cũ',
          ),
        ),
      );
      return;
    }

    final ok = await showConfirmSheet<bool>(
      context,
      title: 'Xác nhận tạo hóa đơn',
      subtitle: 'Tạo hóa đơn tháng này cho phòng ${room.bhRoomNumber}?',
      confirmLabel: 'Tạo hóa đơn',
    );

    if (ok != true || !mounted) return;

    setState(() {
      _submitting = true;
    });

    try {
      final ownerUid = context.read<AuthProvider>().currentUser!.uid;

      // ───────────────── GET PRICE CONFIG ─────────────────

      final config = await ServiceConfigService.getPrices(
        ownerUid,
      );

      final electricPrice = (config['electricPrice'] ?? 3500).toDouble();

      final waterPrice = (config['waterPrice'] ?? 15000).toDouble();

      // ───────────────── UPLOAD IMAGE ─────────────────

      String electricImage = '';
      String waterImage = '';

      if (_electricImagePath != null) {
        electricImage = await CloudinaryService.uploadBillImage(
              imageFile: File(_electricImagePath!),
              tenantName: room.bhRoomTenantName ?? 'USER',
            ) ??
            '';
      }

      if (_waterImagePath != null) {
        waterImage = await CloudinaryService.uploadBillImage(
              imageFile: File(_waterImagePath!),
              tenantName: room.bhRoomTenantName ?? 'USER',
            ) ??
            '';
      }

      // ───────────────── CREATE BILL ─────────────────

      final error = await context.read<BillProvider>().createBill(
            ownerId: ownerUid,
            roomId: room.bhRoomId,
            tenantId: room.bhRoomTenantId!,
            roomNumber: room.bhRoomNumber,
            oldElectric: room.bhRoomLastElec,
            newElectric: currElec,
            electricPrice: electricPrice,
            electricImage: electricImage,
            oldWater: room.bhRoomLastWater,
            newWater: currWater,
            waterPrice: waterPrice,
            waterImage: waterImage,
          );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
          ),
        );
        return;
      }

      // update local room reading
      // nhớ viết hàm này trong provider/service
      await bhPvd.updateLastReading(
        roomId: room.bhRoomId,
        electric: currElec,
        water: currWater,
      );

      if (!mounted) return;

      setState(() {
        _successMsg = 'Đã tạo hóa đơn phòng ${room.bhRoomNumber}';

        _selectedRoomId = null;

        _currElecCtrl.clear();
        _currWaterCtrl.clear();

        _electricImagePath = null;
        _waterImagePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo hóa đơn thành công'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bhPvd = context.watch<BoardingHouseProvider>();

    final billPvd = context.watch<BillProvider>();

    final blocks = bhPvd.bhList;

    final fmt = NumberFormat(
      '#,###',
      'vi_VN',
    );

    List<BhRoomModel> rooms = [];

    BhRoomModel? selectedRoom;

    if (_selectedBlockId != null) {
      rooms = bhPvd
          .roomsOf(_selectedBlockId!)
          .where(
            (r) => r.bhRoomStatus == BhRoomStatus.occupied,
          )
          .toList();
    }

    if (_selectedRoomId != null) {
      selectedRoom = bhPvd
          .roomsOf(_selectedBlockId!)
          .where(
            (r) => r.bhRoomId == _selectedRoomId,
          )
          .firstOrNull;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Tạo hóa đơn điện nước'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_successMsg != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMsg!,
                        style: const TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // block
            _SectionLabel(
              number: '1',
              label: 'Chọn dãy trọ',
            ),

            const SizedBox(height: 8),

            ...blocks.map(
              (b) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child: _SelectionCard(
                  icon: Icons.apartment,
                  title: b.bhName,
                  subtitle: b.bhAddress,
                  selected: _selectedBlockId == b.bhId,
                  onTap: () {
                    setState(() {
                      _selectedBlockId = b.bhId;

                      _selectedRoomId = null;
                    });
                  },
                ),
              ),
            ),

            // room
            if (_selectedBlockId != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                number: '2',
                label: 'Chọn phòng',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rooms.map((r) {
                  final selected = _selectedRoomId == r.bhRoomId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRoomId = r.bhRoomId;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 200,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            r.bhRoomNumber,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            r.bhRoomTenantName ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white70
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (selectedRoom != null) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                number: '3',
                label: 'Nhập chỉ số',
              ),
              const SizedBox(height: 12),
              _ReadingInput(
                label: '⚡ Điện (kWh)',
                prevValue: selectedRoom.bhRoomLastElec,
                controller: _currElecCtrl,
                color: AppTheme.elecColor,
                unitPrice: _electricPrice,
                fmt: fmt,
              ),
              const SizedBox(height: 12),
              _ReadingInput(
                label: '💧 Nước (m³)',
                prevValue: selectedRoom.bhRoomLastWater,
                controller: _currWaterCtrl,
                color: AppTheme.waterColor,
                unitPrice: _waterPrice,
                fmt: fmt,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                number: '4',
                label: 'Ảnh đồng hồ điện',
              ),
              const SizedBox(height: 8),
              _ImagePickerBox(
                imagePath: _electricImagePath,
                onTap: _pickElectricImage,
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                number: '5',
                label: 'Ảnh đồng hồ nước',
              ),
              const SizedBox(height: 8),
              _ImagePickerBox(
                imagePath: _waterImagePath,
                onTap: _pickWaterImage,
              ),
              const SizedBox(height: 28),
              _submitting || billPvd.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(
                        Icons.receipt_long,
                      ),
                      label: const Text(
                        'Tạo hóa đơn',
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  final String? imagePath;

  final VoidCallback onTap;

  const _ImagePickerBox({
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: imagePath != null
                ? AppTheme.successColor
                : const Color(
                    0xFFE2E8F0,
                  ),
            width: 2,
          ),
        ),
        child: imagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(
                  12,
                ),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.textHint,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chụp ảnh đồng hồ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String number;
  final String label;

  const _SectionLabel({
    required this.number,
    required this.label,
  });

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
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
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
        duration: const Duration(
          milliseconds: 200,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : const Color(
                    0xFFE2E8F0,
                  ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textHint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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

    widget.controller.addListener(
      _update,
    );
  }

  void _update() {
    final v = double.tryParse(widget.controller.text);

    setState(() {
      _calc = v != null && v > widget.prevValue
          ? (v - widget.prevValue) * widget.unitPrice
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: widget.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: widget.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chỉ số cũ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                    Text(
                      widget.fmt.format(
                        widget.prevValue,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppTheme.textHint,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chỉ số mới',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      borderSide: BorderSide(
                        color: widget.color,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_calc != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text(
                  '≈ ${widget.fmt.format(_calc)}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                    fontSize: 14,
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
