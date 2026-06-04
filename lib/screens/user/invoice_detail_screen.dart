import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/invoice_provider_user.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/detail_section.dart';
import '../../widgets/user/info_card.dart';
import '../../widgets/user/info_row.dart';
import '../../widgets/user/payment_method_picker.dart';
import '../../theme/StatusBadge.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final inv = context.watch<InvoiceProviderUser>().allInvoices.firstWhere(
          (i) => i.id == invoice.id,
          orElse: () => invoice,
        );
    final canPay = inv.status == InvoiceStatus.pending;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết hóa đơn'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    inv.blockName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phòng ${inv.roomName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inv.blockAddress,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  StatusBadge.payment(inv.status.name),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice info
                  InfoCard(children: [
                    InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ngày lập',
                        value: dateFmt.format(inv.createdAt)),
                    InfoRow(
                        icon: Icons.schedule,
                        label: 'Hạn thanh toán',
                        value: DateFormat('dd/MM/yyyy').format(inv.dueDate),
                        valueColor:
                            DateTime.now().isAfter(inv.dueDate) && canPay
                                ? AppTheme.errorColor
                                : null),
                  ]),

                  const SizedBox(height: 12),

                  // Electricity detail
                  DetailSection(
                    icon: Icons.bolt,
                    color: AppTheme.elecColor,
                    title: 'Điện',
                    prevReading: inv.prevElec,
                    currReading: inv.currElec,
                    used: inv.elecUsed,
                    unitPrice: inv.elecPrice,
                    total: inv.elecTotal,
                    unit: 'kWh',
                    fmt: fmt,
                  ),
                  const SizedBox(height: 12),

                  // Water detail
                  DetailSection(
                    icon: Icons.water_drop,
                    color: AppTheme.waterColor,
                    title: 'Nước',
                    prevReading: inv.prevWater,
                    currReading: inv.currWater,
                    used: inv.waterUsed,
                    unitPrice: inv.waterPrice,
                    total: inv.waterTotal,
                    unit: 'm³',
                    fmt: fmt,
                  ),
                  const SizedBox(height: 12),

                  // Evidence image
                  if (inv.imagePath != null) ...[
                    const Text('Ảnh đồng hồ đo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(inv.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Grand total
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng cộng',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary)),
                        Text(
                          '${fmt.format(inv.grandTotal)}đ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),

                  // Payment action
                  if (canPay) ...[
                    const SizedBox(height: 20),
                    const Text('Xác nhận thanh toán',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    PaymentMethodPicker(invoiceId: inv.id),
                  ] else if (inv.status == InvoiceStatus.pendingConfirm) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.hourglass_top,
                              color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang chờ chủ trọ xác nhận thanh toán...',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (inv.paidAt != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppTheme.successColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đã thanh toán',
                                  style: TextStyle(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  dateFmt.format(inv.paidAt!),
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12),
                                ),
                                if (inv.paymentMethod != null)
                                  Text(
                                    _methodLabel(inv.paymentMethod!),
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.transfer:
        return 'Chuyển khoản';
      case PaymentMethod.momo:
        return 'Ví MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
    }
  }
}
