import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../theme/app_theme.dart';

class BillDetailScreen extends StatelessWidget {
  final BillModel bill;
  const BillDetailScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final isPaid = bill.status == BillStatus.paid;
    final statusColor = isPaid ? AppTheme.successColor : AppTheme.errorColor;
    final statusLabel = isPaid ? 'Đã thanh toán' : 'Chờ thanh toán';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header gradient ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(bill.monthLabel,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '${fmt.format(bill.total)}đ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('Chi tiết hóa đơn',
                style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Trạng thái ──────────────────────────────────────────
                _InfoCard(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPaid
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trạng thái',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: statusColor)),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(bill.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Điện ────────────────────────────────────────────────
                _InfoCard(
                  title: 'Điện',
                  titleIcon: Icons.bolt,
                  titleColor: AppTheme.elecColor,
                  children: [
                    _Row(
                        label: 'Chỉ số cũ',
                        value:
                            '${bill.electric.oldNumber.toStringAsFixed(0)} kWh'),
                    _Row(
                        label: 'Chỉ số mới',
                        value:
                            '${bill.electric.newNumber.toStringAsFixed(0)} kWh'),
                    _Row(
                        label: 'Tiêu thụ',
                        value:
                            '${bill.electric.used.toStringAsFixed(0)} kWh',
                        bold: true),
                    _Row(
                        label: 'Đơn giá',
                        value:
                            '${fmt.format(bill.electric.unitPrice)}đ/kWh'),
                    _Row(
                        label: 'Thành tiền',
                        value: '${fmt.format(bill.electric.total)}đ',
                        bold: true,
                        color: AppTheme.elecColor),
                    // Ảnh công tơ điện
                    if (bill.electric.image != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          bill.electric.image!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: AppTheme.textHint)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Nước ────────────────────────────────────────────────
                _InfoCard(
                  title: 'Nước',
                  titleIcon: Icons.water_drop,
                  titleColor: AppTheme.waterColor,
                  children: [
                    _Row(
                        label: 'Chỉ số cũ',
                        value:
                            '${bill.water.oldNumber.toStringAsFixed(0)} m³'),
                    _Row(
                        label: 'Chỉ số mới',
                        value:
                            '${bill.water.newNumber.toStringAsFixed(0)} m³'),
                    _Row(
                        label: 'Tiêu thụ',
                        value: '${bill.water.used.toStringAsFixed(0)} m³',
                        bold: true),
                    _Row(
                        label: 'Đơn giá',
                        value:
                            '${fmt.format(bill.water.unitPrice)}đ/m³'),
                    _Row(
                        label: 'Thành tiền',
                        value: '${fmt.format(bill.water.total)}đ',
                        bold: true,
                        color: AppTheme.waterColor),
                    // Ảnh đồng hồ nước
                    if (bill.water.image != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          bill.water.image!,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: AppTheme.textHint)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // ── Tổng cộng ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${fmt.format(bill.total)}đ',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Color? titleColor;
  final List<Widget> children;

  const _InfoCard({
    this.title,
    this.titleIcon,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null)
                  Icon(titleIcon, color: titleColor, size: 18),
                if (titleIcon != null) const SizedBox(width: 6),
                Text(title!,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: titleColor ?? AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 0),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

// ── Row item ─────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _Row(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
