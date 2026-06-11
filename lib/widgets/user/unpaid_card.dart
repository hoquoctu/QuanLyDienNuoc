import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../theme/app_theme.dart';

class UnpaidCard extends StatelessWidget {
  final BillModel bill;
  final NumberFormat fmt;
  const UnpaidCard({required this.bill, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    switch (bill.billStatus) {
      case BillStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Chờ xác nhận';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case BillStatus.overdue:
        statusColor = Colors.deepOrange;
        statusLabel = 'Quá hạn';
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = AppTheme.errorColor;
        statusLabel = 'Chờ thanh toán';
        statusIcon = Icons.warning_amber_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${bill.roomNumberName} · ${bill.month}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(statusLabel,
                    style: TextStyle(fontSize: 12, color: statusColor)),
              ],
            ),
          ),
          Text('${fmt.format(bill.total)}đ',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  fontSize: 15)),
          const Icon(Icons.chevron_right, color: AppTheme.textHint),
        ],
      ),
    );
  }
}
