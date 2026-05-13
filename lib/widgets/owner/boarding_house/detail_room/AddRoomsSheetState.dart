import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/boarding_house_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SHEET THÊM PHÒNG HÀNG LOẠT
// ═══════════════════════════════════════════════════════════════════════════

class AddRoomsSheet extends StatefulWidget {
  final String bhId;
  const AddRoomsSheet({required this.bhId, super.key});

  @override
  State<AddRoomsSheet> createState() => _AddRoomsSheetState();
}

class _AddRoomsSheetState extends State<AddRoomsSheet> {
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
