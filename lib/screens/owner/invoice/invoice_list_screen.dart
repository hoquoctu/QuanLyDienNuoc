import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/bill_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner/bill_provider.dart';
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
    final billPvd = context.watch<BillProvider>();

    final ownerId = context.read<AuthProvider>().currentUser!.uid;
    final ownerName = context.read<AuthProvider>().currentUser!.name;
    final fmt = NumberFormat(
      '#,###',
      'vi_VN',
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Danh sách hóa đơn',
        ),
      ),
      body: Column(
        children: [
          // FILTER
          // thay phần FILTER hiện tại
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.filter_list,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                // Month picker
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Tháng',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('Tháng $m'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedMonth = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Year picker
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Năm',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(3, (i) => DateTime.now().year - i)
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedYear = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          // DATA
          Expanded(
            child: StreamBuilder<List<BillModel>>(
              stream: billPvd.streamBillsByMonth(
                ownerId: ownerId,
                month:
                    '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final bills = snapshot.data ?? [];

                // SUMMARY
                final paidCount = bills.where(
                  (e) {
                    return e.status.id == 'paid';
                  },
                ).length;

                final unpaidCount = bills.where(
                  (e) {
                    return e.status.id == 'unpaid';
                  },
                ).length;

                if (bills.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có hóa đơn',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(
                        16,
                      ),
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryChip(
                            label: 'Tổng HĐ',
                            value: '${bills.length}',
                            sub: 'hóa đơn',
                          ),
                          _SummaryChip(
                            label: 'Đã thanh toán',
                            value: '$paidCount',
                            sub: 'phòng',
                          ),
                          _SummaryChip(
                            label: 'Chưa thanh toán',
                            value: '$unpaidCount',
                            sub: 'phòng',
                          ),
                        ],
                      ),
                    ),

                    // LIST
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          24,
                        ),
                        itemCount: bills.length,
                        separatorBuilder: (_, __) => const SizedBox(
                          height: 10,
                        ),
                        itemBuilder: (ctx, i) {
                          final bill = bills[i];

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(
                                    0,
                                    2,
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: Text(
                                        bill.roomNumberName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Text(
                                        bill.month,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    StatusBadge.bill(
                                      bill.status.id,
                                    ),
                                  ],
                                ),

                                const Divider(
                                  height: 16,
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Điện: ${bill.electric.used.toStringAsFixed(0)} số : ${bill.electric.total.toStringAsFixed(0)}đ',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Nước: ${bill.water.used.toStringAsFixed(0)} m³ : ${bill.water.total.toStringAsFixed(0)}đ',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textHint,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${fmt.format(bill.total)}đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
// HỦY KHI UNPAID
                                if (bill.status.id == 'unpaid') ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Hủy hóa đơn'),
                                            content: Text(
                                              'Bạn có chắc muốn hủy hóa đơn phòng ${bill.roomNumberName} tháng ${bill.month}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Không'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Hủy hóa đơn',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await billPvd.cancelBill(
                                            bill: bill,
                                            ownerId: ownerId,
                                            ownerName: ownerName,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red),
                                      label: const Text('Hủy hóa đơn',
                                          style: TextStyle(color: Colors.red)),
                                      style: OutlinedButton.styleFrom(
                                        side:
                                            const BorderSide(color: Colors.red),
                                        minimumSize: const Size(0, 40),
                                      ),
                                    ),
                                  ),
                                ],
                                // OWNER CONFIRM
                                if (bill.status.id == 'pending') ...[
                                  const SizedBox(height: 12),

                                  // Hiển thị phương thức thanh toán
                                  if (bill.method == 'transfer') ...[
                                    // TRANSFER: hiện ảnh
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        bill.transfeImage ?? '',
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            height: 180,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          );
                                        },
                                        errorBuilder: (ctx, _, __) => Container(
                                          height: 180,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image_outlined,
                                                  color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text('Không tải được ảnh',
                                                  style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.account_balance_outlined,
                                            size: 14,
                                            color: AppTheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Chuyển khoản',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else if (bill.method == 'cash') ...[
                                    // CASH: hiện dòng phương thức
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                                Colors.orange.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.payments_outlined,
                                              size: 16, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text(
                                            'Phương thức: Tiền mặt',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Nút từ chối
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await billPvd.ownerConfirm(
                                              bill: bill,
                                              statusKey: 'unpaid',
                                              ownerId: ownerId,
                                              ownerName: ownerName,
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.cancel_outlined,
                                              size: 16,
                                              color: AppTheme.errorColor),
                                          label: const Text('Chưa nhận được',
                                              style: TextStyle(
                                                  color: AppTheme.errorColor)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                                color: AppTheme.errorColor),
                                            minimumSize: const Size(0, 40),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Nút xác nhận
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            await billPvd.ownerConfirm(
                                              bill: bill,
                                              statusKey: 'paid',
                                              ownerId: ownerId,
                                              ownerName: ownerName,
                                            );
                                          },
                                          icon: const Icon(
                                              Icons.check_circle_outline,
                                              size: 16),
                                          label: const Text('Xác nhận'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.successColor,
                                            minimumSize: const Size(0, 40),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
