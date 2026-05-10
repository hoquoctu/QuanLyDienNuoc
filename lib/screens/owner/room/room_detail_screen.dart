import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/invoice_model.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final room = context.read<RoomProvider>().getById(roomId);
    final invoices = context.watch<InvoiceProvider>().invoicesForRoom(roomId);
    final fmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Phòng ${room?.name ?? roomId}'),
      ),
      body: invoices.isEmpty
          ? const Center(
              child: Text('Chưa có hóa đơn nào',
                  style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final inv = invoices[i];
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
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_outlined,
                            color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy', 'vi_VN')
                                  .format(inv.createdAt),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text('Ngày lập: ${dateFmt.format(inv.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            StatusBadge.invoice(inv.status),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${fmt.format(inv.grandTotal)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (inv.status == InvoiceStatus.pendingConfirm)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 30),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  backgroundColor: AppTheme.successColor,
                                ),
                                onPressed: () => context
                                    .read<InvoiceProvider>()
                                    .confirmPayment(inv.id),
                                child: const Text('Duyệt',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
