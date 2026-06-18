import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/invoice_provider_user.dart';
import '../../models/invoice_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_sheet_confirm.dart';

class PaymentMethodPicker extends StatefulWidget {
  final String invoiceId;
  const PaymentMethodPicker({super.key, required this.invoiceId});

  @override
  State<PaymentMethodPicker> createState() => _PaymentMethodPickerState();
}

class _PaymentMethodPickerState extends State<PaymentMethodPicker> {
  PaymentMethod _selected = PaymentMethod.transfer;

  static const _methods = [
    (PaymentMethod.cash, '💵 Tiền mặt', Icons.payments_outlined),
    (PaymentMethod.transfer, '🏦 Chuyển khoản', Icons.account_balance_outlined),
    (PaymentMethod.momo, '💜 MoMo', Icons.phone_android_outlined),
    (PaymentMethod.vnpay, '🔴 VNPay', Icons.credit_card_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...(_methods.map((m) {
          final method = m.$1;
          final label = m.$2;
          final icon = m.$3;
          final selected = _selected == method;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selected = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        selected ? AppTheme.primary : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon,
                        color: selected ? AppTheme.primary : AppTheme.textHint),
                    const SizedBox(width: 12),
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary)),
                    const Spacer(),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        })),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final ok = await showConfirmSheet<bool>(
              context,
              title: 'Xác nhận đã thanh toán',
              subtitle: 'Chủ trọ sẽ xác nhận sau khi nhận được thanh toán.',
              confirmLabel: 'Gửi xác nhận',
            );
            if (ok == true && context.mounted) {
              await context
                  .read<InvoiceProviderUser>()
                  .reportPayment(widget.invoiceId, _selected);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã gửi xác nhận, chờ chủ trọ duyệt!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.send_outlined),
          label: const Text('Xác nhận đã thanh toán'),
        ),
      ],
    );
  }
}
