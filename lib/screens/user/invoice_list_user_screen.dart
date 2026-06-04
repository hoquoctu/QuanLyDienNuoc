import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/invoice_provider_user.dart';
import '../../models/invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user/invoice_card.dart';
import '../../widgets/user/section_header.dart';

class InvoiceListUserScreen extends StatelessWidget {
  const InvoiceListUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final invoices =
        context.watch<InvoiceProviderUser>().invoicesForTenant(user.uid);

    final unpaid = invoices
        .where((i) =>
            i.status == InvoiceStatus.pending ||
            i.status == InvoiceStatus.pendingConfirm)
        .toList();
    final paid = invoices
        .where((i) =>
            i.status == InvoiceStatus.paid ||
            i.status == InvoiceStatus.paidLate)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Hóa đơn của tôi')),
      body: invoices.isEmpty
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
                  SectionHeader(
                    icon: Icons.pending_outlined,
                    label: 'Chờ thanh toán',
                    count: unpaid.length,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  ...unpaid.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InvoiceCard(invoice: i),
                      )),
                  const SizedBox(height: 16),
                ],
                if (paid.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.check_circle_outline,
                    label: 'Đã thanh toán',
                    count: paid.length,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 8),
                  ...paid.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InvoiceCard(invoice: i),
                      )),
                ],
              ],
            ),
    );
  }
}
