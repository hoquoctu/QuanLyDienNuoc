// screens/manager/payment_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/payment_model.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import '../../../services/manager/payment_service.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  late int _selectedMonth;
  late int _selectedYear;
  late String _month;
  final fmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    _month = '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';
    print(_month);
  }

  void _onMonthChanged(String val) {
    final parts = val.split('-');
    setState(() {
      _selectedYear = int.parse(parts[0]);
      _selectedMonth = int.parse(parts[1]);
      _month = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = context.read<AuthProvider>().currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
      ),
      body: Column(
        children: [
          // FILTER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.filter_list,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                // Tháng hiện tại & tháng trước
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _month,
                    decoration: const InputDecoration(
                      labelText: 'Tháng',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _buildMonthItems(),
                    onChanged: (v) {
                      if (v != null) {
                        _onMonthChanged(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // LIST
          Expanded(
            child: StreamBuilder<List<PaymentModel>>(
              key: ValueKey(_month),
              stream: PaymentService.streamPaymentsByOwner(
                ownerId: ownerId,
                month: _month,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data ?? [];

                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có thanh toán nào',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                // SUMMARY
                final totalAmount =
                    payments.fold(0.0, (sum, p) => sum + p.total);

                return Column(
                  children: [
                    // SUMMARY CARD
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
                            label: 'Tổng giao dịch',
                            value: '${payments.length}',
                            sub: 'phòng',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          _SummaryChip(
                            label: 'Tổng thu',
                            value: fmt.format(totalAmount),
                            sub: 'đồng',
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final p = payments[i];
                          return _PaymentCard(payment: p, fmt: fmt);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildMonthItems() {
    final now = DateTime.now();
    final months = <DateTime>[];

    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i);
      months.add(d);
    }

    return months.asMap().entries.map((entry) {
      final index = entry.key; // index = 0,1,2,3,4,5
      final d = entry.value; // DateTime
      final val = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final label = index == 0 // dùng index thay vì i
          ? 'Tháng ${d.month}/${d.year} (hiện tại)'
          : 'Tháng ${d.month}/${d.year}';
      return DropdownMenuItem(value: val, child: Text(label));
    }).toList();
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final NumberFormat fmt;

  const _PaymentCard({required this.payment, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isTransfer = payment.method == 'transfer';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.roomNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payment.tenantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Đã thanh toán',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // BODY
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phương thức
                  Row(
                    children: [
                      Icon(
                        isTransfer
                            ? Icons.account_balance_outlined
                            : Icons.payments_outlined,
                        size: 13,
                        color: isTransfer ? AppTheme.primary : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTransfer ? 'Chuyển khoản' : 'Tiền mặt',
                        style: TextStyle(
                          fontSize: 12,
                          color: isTransfer ? AppTheme.primary : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
              Text(
                '${fmt.format(payment.total)}đ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          // Ảnh chuyển khoản
          if (isTransfer && payment.transferImage.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                payment.transferImage,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 160,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, _, __) => Container(
                  height: 80,
                  color: Colors.grey[100],
                  child: const Center(
                    child:
                        Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.sub,
  });

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
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
