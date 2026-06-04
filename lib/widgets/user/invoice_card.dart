import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/user/invoice_detail_screen.dart';
import '../../theme/StatusBadge.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceDetailScreen(invoice: invoice),
        ),
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
                      Text(invoice.blockName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Phòng ${invoice.roomName}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                StatusBadge.payment(invoice.status.name),
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
                        Text('${fmt.format(invoice.elecTotal)}đ',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.water_drop,
                            color: AppTheme.waterColor, size: 14),
                        const SizedBox(width: 4),
                        Text('${fmt.format(invoice.waterTotal)}đ',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(dateFmt.format(invoice.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${fmt.format(invoice.grandTotal)}đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
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
