// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../models/invoice_model.dart';
// import '../../providers/auth_provider.dart';
// import '../../providers/invoice_provider.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/status_badge.dart';
// import 'invoice_detail_screen.dart';

// class InvoiceListUserScreen extends StatelessWidget {
//   const InvoiceListUserScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = context.read<AuthProvider>().currentUser!;
//     final invoices =
//         context.watch<InvoiceProvider>().invoicesForTenant(user.uid);

//     final unpaid = invoices
//         .where((i) =>
//             i.status == InvoiceStatus.waitingPayment ||
//             i.status == InvoiceStatus.pendingConfirm)
//         .toList();
//     final paid = invoices
//         .where((i) =>
//             i.status == InvoiceStatus.paid ||
//             i.status == InvoiceStatus.paidLate)
//         .toList();

//     return Scaffold(
//       backgroundColor: AppTheme.surface,
//       appBar: AppBar(title: const Text('Hóa đơn của tôi')),
//       body: invoices.isEmpty
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.receipt_long_outlined,
//                       size: 72, color: AppTheme.textHint),
//                   SizedBox(height: 16),
//                   Text('Chưa có hóa đơn nào',
//                       style: TextStyle(color: AppTheme.textSecondary)),
//                 ],
//               ),
//             )
//           : ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 if (unpaid.isNotEmpty) ...[
//                   _SectionHeader(
//                     icon: Icons.pending_outlined,
//                     label: 'Chờ thanh toán',
//                     count: unpaid.length,
//                     color: AppTheme.errorColor,
//                   ),
//                   const SizedBox(height: 8),
//                   ...unpaid.map((i) => Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: _InvoiceCard(invoice: i),
//                       )),
//                   const SizedBox(height: 16),
//                 ],
//                 if (paid.isNotEmpty) ...[
//                   _SectionHeader(
//                     icon: Icons.check_circle_outline,
//                     label: 'Đã thanh toán',
//                     count: paid.length,
//                     color: AppTheme.successColor,
//                   ),
//                   const SizedBox(height: 8),
//                   ...paid.map((i) => Padding(
//                         padding: const EdgeInsets.only(bottom: 8),
//                         child: _InvoiceCard(invoice: i),
//                       )),
//                 ],
//               ],
//             ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final int count;
//   final Color color;
//   const _SectionHeader(
//       {required this.icon,
//       required this.label,
//       required this.count,
//       required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Icon(icon, color: color, size: 18),
//         const SizedBox(width: 6),
//         Text(label,
//             style: TextStyle(
//                 fontWeight: FontWeight.w700, fontSize: 14, color: color)),
//         const SizedBox(width: 6),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text('$count',
//               style: TextStyle(
//                   fontSize: 11, fontWeight: FontWeight.w700, color: color)),
//         ),
//       ],
//     );
//   }
// }

// class _InvoiceCard extends StatelessWidget {
//   final InvoiceModel invoice;
//   const _InvoiceCard({required this.invoice});

//   @override
//   Widget build(BuildContext context) {
//     final fmt = NumberFormat('#,###', 'vi_VN');
//     final dateFmt = DateFormat('dd/MM/yyyy');

//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => InvoiceDetailScreen(invoice: invoice),
//         ),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2))
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(invoice.blockName,
//                           style: const TextStyle(
//                               fontWeight: FontWeight.w700, fontSize: 14)),
//                       Text('Phòng ${invoice.roomName}',
//                           style: const TextStyle(
//                               fontSize: 12, color: AppTheme.textSecondary)),
//                     ],
//                   ),
//                 ),
//                 StatusBadge.invoice(invoice.status),
//               ],
//             ),
//             const Divider(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(Icons.bolt,
//                             color: AppTheme.elecColor, size: 14),
//                         const SizedBox(width: 4),
//                         Text('${fmt.format(invoice.elecTotal)}đ',
//                             style: const TextStyle(
//                                 fontSize: 12, color: AppTheme.textSecondary)),
//                       ],
//                     ),
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         const Icon(Icons.water_drop,
//                             color: AppTheme.waterColor, size: 14),
//                         const SizedBox(width: 4),
//                         Text('${fmt.format(invoice.waterTotal)}đ',
//                             style: const TextStyle(
//                                 fontSize: 12, color: AppTheme.textSecondary)),
//                       ],
//                     ),
//                     const SizedBox(height: 2),
//                     Text(dateFmt.format(invoice.createdAt),
//                         style: const TextStyle(
//                             fontSize: 11, color: AppTheme.textHint)),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       '${fmt.format(invoice.grandTotal)}đ',
//                       style: const TextStyle(
//                           fontWeight: FontWeight.w900,
//                           fontSize: 18,
//                           color: AppTheme.textPrimary),
//                     ),
//                     const Icon(Icons.chevron_right, color: AppTheme.textHint),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
