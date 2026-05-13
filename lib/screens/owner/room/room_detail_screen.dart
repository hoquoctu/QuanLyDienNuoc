import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/bill_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final roomPvd = context.read<RoomProvider>();
    final billPvd = context.watch<BillProvider>();

    final room = roomPvd.getById(roomId);

    final bills = billPvd.getBillsByRoom(roomId)
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Phòng ${room?.name ?? roomId}',
        ),
      ),
      body: bills.isEmpty
          ? const Center(
              child: Text(
                'Chưa có hóa đơn nào',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bill = bills[index];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hóa đơn ${bill.month}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ngày tạo: ${dateFmt.format(bill.createdAt.toDate())}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge.bill(
                            bill.status.id,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      const Divider(height: 1),

                      const SizedBox(height: 14),

                      // ELECTRIC + WATER
                      Row(
                        children: [
                          Expanded(
                            child: _UtilityBox(
                              icon: Icons.bolt,
                              color: AppTheme.elecColor,
                              title: 'Điện',
                              used:
                                  '${bill.electric.used.toStringAsFixed(0)} kWh',
                              total: '${fmt.format(bill.electric.total)}đ',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _UtilityBox(
                              icon: Icons.water_drop,
                              color: AppTheme.waterColor,
                              title: 'Nước',
                              used: '${bill.water.used.toStringAsFixed(0)} m³',
                              total: '${fmt.format(bill.water.total)}đ',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // TOTAL
                      Row(
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${fmt.format(bill.total)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),

                      // BUTTON
                      if (bill.status.id == 'pending')
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            onPressed: () async {
                              await context
                                  .read<BillProvider>()
                                  .ownerConfirmPaid(
                                    billId: bill.id,
                                  );
                            },
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: const Text(
                              'Xác nhận đã thanh toán',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _UtilityBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String used;
  final String total;

  const _UtilityBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            used,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            total,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
