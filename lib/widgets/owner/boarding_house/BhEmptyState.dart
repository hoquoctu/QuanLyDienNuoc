import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

class BhEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const BhEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apartment_outlined,
              size: 72, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'Chưa có dãy trọ nào',
            style: TextStyle(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm dãy trọ đầu tiên'),
          ),
        ],
      ),
    );
  }
}
