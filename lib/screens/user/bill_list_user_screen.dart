import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/providers/user/bill_provider_user.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart'; // thêm
import '../../theme/app_theme.dart';
import '../../widgets/user/bill_card.dart';
import '../../widgets/user/section_header.dart';

class BillListUserScreen extends StatefulWidget {
  // đổi thành StatefulWidget
  const BillListUserScreen({super.key});

  @override
  State<BillListUserScreen> createState() => _BillListUserScreenState();
}

class _BillListUserScreenState extends State<BillListUserScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Lấy tenantId từ AuthProvider, gọi init stream
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<BillProviderUser>().initForUser(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final billPvd = context.watch<BillProviderUser>();
    final cancelled = billPvd.cancelledBills;

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
                  SectionHeader(
                    icon: Icons.pending_outlined,
                    label: 'Chưa thanh toán',
                    count: unpaid.length,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  ...unpaid.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BillCard(bill: b),
                      )),
                  const SizedBox(height: 16),
                ],
                if (pending.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.hourglass_top_rounded,
                    label: 'Chờ xác nhận',
                    count: pending.length,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BillCard(bill: b),
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
                  ...paid.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BillCard(bill: b),
                      )),
                ],
                if (cancelled.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionHeader(
                    icon: Icons.cancel_outlined,
                    label: 'Đã hủy',
                    count: cancelled.length,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  ...cancelled.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BillCard(bill: b),
                      )),
                ],
              ],
            ),
    );
  }
}
