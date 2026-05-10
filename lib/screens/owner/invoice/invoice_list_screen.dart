import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/invoice_model.dart';
import '../../../providers/invoice_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final invPvd = context.watch<InvoiceProvider>();
    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    // Get all invoices for manager's blocks
    final all = invPvd.allInvoices
        .where((i) =>
            i.createdAt.month == _selectedMonth &&
            i.createdAt.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Danh sách hóa đơn')),
      body: Column(
        children: [
          // Month filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Tháng:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  ...List.generate(5, (i) {
                    final now = DateTime.now();
                    final m =
                        DateTime(now.year, now.month - i);
                    final active = m.month == _selectedMonth &&
                        m.year == _selectedYear;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedMonth = m.month;
                          _selectedYear = m.year;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.primary
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('T.M/yy').format(m),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Summary
          if (all.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                      label: 'Tổng HĐ',
                      value: '${all.length}',
                      sub: 'hóa đơn'),
                  _SummaryChip(
                      label: 'Đã thanh toán',
                      value:
                          '${all.where((i) => i.status == InvoiceStatus.paid || i.status == InvoiceStatus.paidLate).length}',
                      sub: 'phòng'),
                  _SummaryChip(
                      label: 'Chờ thanh toán',
                      value:
                          '${all.where((i) => i.status == InvoiceStatus.waitingPayment).length}',
                      sub: 'phòng'),
                ],
              ),
            ),

          // List
          Expanded(
            child: all.isEmpty
                ? const Center(
                    child: Text('Chưa có hóa đơn trong tháng này',
                        style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final inv = all[i];
                      return Container(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(inv.roomName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                          fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(inv.blockName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13))),
                                StatusBadge.invoice(inv.status),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(inv.tenantName,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary)),
                                    Text(dateFmt.format(inv.createdAt),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textHint)),
                                  ],
                                ),
                                Text(
                                  '${fmt.format(inv.grandTotal)}đ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            if (inv.status == InvoiceStatus.pendingConfirm) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => context
                                    .read<InvoiceProvider>()
                                    .confirmPayment(inv.id),
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 16),
                                label: const Text(
                                    'Xác nhận đã thanh toán'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _SummaryChip(
      {required this.label, required this.value, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        Text(sub,
            style: const TextStyle(
                color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
