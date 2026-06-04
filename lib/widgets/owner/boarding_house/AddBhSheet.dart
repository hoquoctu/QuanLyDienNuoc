// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET THÊM DÃY TRỌ
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/owner/boarding_house_provider.dart';

class AddBhSheet extends StatefulWidget {
  final String ownerUid;
  const AddBhSheet({required this.ownerUid, super.key});

  @override
  State<AddBhSheet> createState() => _AddBhSheetState();
}

class _AddBhSheetState extends State<AddBhSheet> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final err = await context.read<BoardingHouseProvider>().addBh(
          ownerUid: widget.ownerUid,
          name: _nameCtrl.text,
          address: _addrCtrl.text,
          description: _descCtrl.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ KEY FIX: dùng SingleChildScrollView + viewInsets.bottom
    // để sheet đẩy lên khi bàn phím thật xuất hiện
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Thêm dãy trọ mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên dãy trọ *',
                  hintText: 'VD: Dãy Trọ Bình Minh',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addrCtrl,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ *',
                  hintText: 'VD: 123 Đường ABC, Quận 9',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tuỳ chọn)',
                  hintText: 'VD: Trọ giá rẻ, sạch sẽ',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
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
                      : const Text('Thêm dãy trọ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
