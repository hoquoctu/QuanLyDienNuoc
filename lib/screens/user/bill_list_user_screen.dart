import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/bill_provider_user.dart';
import '../../models/bill_model.dart';
import '../../theme/app_theme.dart';
import 'bill_detail_screen.dart';

class BillListUserScreen extends StatelessWidget {
  const BillListUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billPvd = context.watch<BillProviderUser>();

    if (billPvd.loading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (billPvd.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Hóa đơn của tôi')),
        body: Center(
          child: Text(billPvd.error!,
              style: const TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final bills = billPvd.bills;
    final unpaid = billPvd.unpaidBills;
    final pending = billPvd.pendingBills;
    final paid = billPvd.paidBills;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Hóa đơn của tôi')),
      body: bills.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 72, color: AppTheme.textHint),
                  SizedBox(height: 16),
                  Text('Chưa có hóa đơn nào',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unpaid.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.pending_outlined,
                    label: 'Chưa thanh toán',
                    count: unpaid.length,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  ...unpaid.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BillCard(bill: b),
                      )),
                  const SizedBox(height: 16),
                ],
                if (pending.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Chờ xác nhận',
                    count: pending.length,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BillCard(bill: b),
                      )),
                  const SizedBox(height: 16),
                ],
                if (paid.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.check_circle_outline,
                    label: 'Đã thanh toán',
                    count: paid.length,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 8),
                  ...paid.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BillCard(bill: b),
                      )),
                ],
              ],
            ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.icon,
      required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: color)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

// ── Bill Card ────────────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final BillModel bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    final Color statusColor;
    final String statusLabel;

    switch (bill.status) {
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
      default: // unpaid
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
            // Header
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
            // Điện & nước
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
