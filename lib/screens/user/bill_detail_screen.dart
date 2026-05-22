import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bill_model.dart';
import '../../models/payment_model.dart';
import '../../services/bill_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/bill_payment_info.dart';
import '../../widgets/user/bill_payment_sheet.dart';
import '../../widgets/user/detail_row.dart';
import '../../widgets/user/info_card.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;
  const BillDetailScreen({super.key, required this.bill});
  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  PaymentModel? _payment;
  bool _loadingPayment = false;
  BillModel get bill => widget.bill;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() => _loadingPayment = true);
    final payment = await BillService.instance.getPaymentByBill(bill.id);
    if (mounted) {
      setState(() {
        _payment = payment;
        _loadingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');

    // Trạng thái hiển thị
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (bill.status) {
      case BillStatus.paid:
        statusColor = AppTheme.successColor;
        statusLabel = 'Đã thanh toán';
        statusIcon = Icons.check_circle_outline;
        break;
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
        statusIcon = Icons.pending_outlined;
    }

    // Chỉ hiển thị nút thanh toán khi chưa TT (unpaid / overdue)
    final showPayButton =
        bill.status == BillStatus.unpaid || bill.status == BillStatus.overdue;

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
                InfoCard(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
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
                InfoCard(
                  title: 'Điện',
                  titleIcon: Icons.bolt,
                  titleColor: AppTheme.elecColor,
                  children: [
                    DetailRow(
                        label: 'Chỉ số cũ',
                        value:
                            '${bill.electric.oldNumber.toStringAsFixed(0)} kWh'),
                    DetailRow(
                        label: 'Chỉ số mới',
                        value:
                            '${bill.electric.newNumber.toStringAsFixed(0)} kWh'),
                    DetailRow(
                        label: 'Tiêu thụ',
                        value: '${bill.electric.used.toStringAsFixed(0)} kWh',
                        bold: true),
                    DetailRow(
                        label: 'Đơn giá',
                        value: '${fmt.format(bill.electric.unitPrice)}đ/kWh'),
                    DetailRow(
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
                InfoCard(
                  title: 'Nước',
                  titleIcon: Icons.water_drop,
                  titleColor: AppTheme.waterColor,
                  children: [
                    DetailRow(
                        label: 'Chỉ số cũ',
                        value: '${bill.water.oldNumber.toStringAsFixed(0)} m³'),
                    DetailRow(
                        label: 'Chỉ số mới',
                        value: '${bill.water.newNumber.toStringAsFixed(0)} m³'),
                    DetailRow(
                        label: 'Tiêu thụ',
                        value: '${bill.water.used.toStringAsFixed(0)} m³',
                        bold: true),
                    DetailRow(
                        label: 'Đơn giá',
                        value: '${fmt.format(bill.water.unitPrice)}đ/m³'),
                    DetailRow(
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
                const SizedBox(height: 16),

                // ── Nút thanh toán ──────────────────────────────────────
                if (showPayButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () { showBillPaymentSheet(context, bill); },
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text('Thanh toán ngay',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                // ── Thông tin thanh toán ──────────────────────────────────
                if (_loadingPayment || _payment != null) ...[
                  const SizedBox(height: 4),
                  BillPaymentInfo(loading: _loadingPayment, payment: _payment, bill: bill),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
