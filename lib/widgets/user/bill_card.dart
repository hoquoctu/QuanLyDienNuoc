import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/user/bill_detail_screen.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;
  const BillCard({required this.bill, super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    final Color statusColor;
    final String statusLabel;

    switch (bill.billStatus) {
      case BillStatus.paid:
        statusColor = AppTheme.successColor;
        statusLabel = 'Đã thanh toán';
        break;
      case BillStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Chờ xác nhận';
        break;
      case BillStatus.overdue:
        statusColor = Colors.deepOrange;
        statusLabel = 'Quá hạn';
        break;
      default:
        statusColor = AppTheme.errorColor;
        statusLabel = 'Chưa thanh toán';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.month,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(
                        DateFormat('dd/MM/yyyy')
                            .format(bill.createdAt.toDate()),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: AppTheme.elecColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${bill.electric.used.toStringAsFixed(0)} kWh · ${fmt.format(bill.electric.total)}đ',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.water_drop,
                            color: AppTheme.waterColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${bill.water.used.toStringAsFixed(0)} m³ · ${fmt.format(bill.water.total)}đ',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${fmt.format(bill.total)}đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppTheme.textPrimary),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textHint),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
