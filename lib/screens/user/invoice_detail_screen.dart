// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../models/invoice_model.dart';
// import '../../providers/invoice_provider.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/bottom_sheet_confirm.dart';
// import '../../widgets/status_badge.dart';

// class InvoiceDetailScreen extends StatelessWidget {
//   final InvoiceModel invoice;
//   const InvoiceDetailScreen({super.key, required this.invoice});

//   @override
//   Widget build(BuildContext context) {
//     final fmt = NumberFormat('#,###', 'vi_VN');
//     final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
//     final inv =
//         context.watch<InvoiceProvider>().allInvoices.firstWhere(
//               (i) => i.id == invoice.id,
//               orElse: () => invoice,
//             );
//     final canPay = inv.status == InvoiceStatus.waitingPayment;

//     return Scaffold(
//       backgroundColor: AppTheme.surface,
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Chi tiết hóa đơn'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Header
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(24),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [AppTheme.primary, AppTheme.primaryDark],
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     inv.blockName,
//                     style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w800),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Phòng ${inv.roomName}',
//                     style: const TextStyle(
//                         color: Colors.white70, fontSize: 14),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     inv.blockAddress,
//                     style: const TextStyle(
//                         color: Colors.white60, fontSize: 12),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 12),
//                   StatusBadge.invoice(inv.status),
//                 ],
//               ),
//             ),

//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Invoice info
//                   _InfoCard(children: [
//                     _InfoRow(
//                         icon: Icons.calendar_today_outlined,
//                         label: 'Ngày lập',
//                         value: dateFmt.format(inv.createdAt)),
//                     _InfoRow(
//                         icon: Icons.schedule,
//                         label: 'Hạn thanh toán',
//                         value: DateFormat('dd/MM/yyyy').format(inv.dueDate),
//                         valueColor: DateTime.now().isAfter(inv.dueDate) &&
//                                 canPay
//                             ? AppTheme.errorColor
//                             : null),
//                   ]),

//                   const SizedBox(height: 12),

//                   // Electricity detail
//                   _DetailSection(
//                     icon: Icons.bolt,
//                     color: AppTheme.elecColor,
//                     title: 'Điện',
//                     prevReading: inv.prevElec,
//                     currReading: inv.currElec,
//                     used: inv.elecUsed,
//                     unitPrice: inv.elecPrice,
//                     total: inv.elecTotal,
//                     unit: 'kWh',
//                     fmt: fmt,
//                   ),
//                   const SizedBox(height: 12),

//                   // Water detail
//                   _DetailSection(
//                     icon: Icons.water_drop,
//                     color: AppTheme.waterColor,
//                     title: 'Nước',
//                     prevReading: inv.prevWater,
//                     currReading: inv.currWater,
//                     used: inv.waterUsed,
//                     unitPrice: inv.waterPrice,
//                     total: inv.waterTotal,
//                     unit: 'm³',
//                     fmt: fmt,
//                   ),
//                   const SizedBox(height: 12),

//                   // Evidence image
//                   if (inv.imagePath != null) ...[
//                     const Text('Ảnh đồng hồ đo',
//                         style: TextStyle(
//                             fontWeight: FontWeight.w700, fontSize: 13)),
//                     const SizedBox(height: 8),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(14),
//                       child: Image.file(
//                         File(inv.imagePath!),
//                         fit: BoxFit.cover,
//                         width: double.infinity,
//                         height: 180,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                   ],

//                   // Grand total
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4))
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisAlignment:
//                           MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('Tổng cộng',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 15,
//                                 color: AppTheme.textPrimary)),
//                         Text(
//                           '${fmt.format(inv.grandTotal)}đ',
//                           style: const TextStyle(
//                               fontWeight: FontWeight.w900,
//                               fontSize: 22,
//                               color: AppTheme.primary),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Payment action
//                   if (canPay) ...[
//                     const SizedBox(height: 20),
//                     const Text('Xác nhận thanh toán',
//                         style: TextStyle(
//                             fontWeight: FontWeight.w700, fontSize: 15)),
//                     const SizedBox(height: 8),
//                     _PaymentMethodPicker(invoiceId: inv.id),
//                   ] else if (inv.status == InvoiceStatus.pendingConfirm) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: AppTheme.primary.withOpacity(0.06),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: const [
//                           Icon(Icons.hourglass_top,
//                               color: AppTheme.primary, size: 20),
//                           SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Đang chờ chủ trọ xác nhận thanh toán...',
//                               style: TextStyle(
//                                   color: AppTheme.primary,
//                                   fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ] else if (inv.paidAt != null) ...[
//                     const SizedBox(height: 16),
//                     Container(
//                       padding: const EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: AppTheme.successColor.withOpacity(0.06),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.check_circle,
//                               color: AppTheme.successColor),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment:
//                                   CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   'Đã thanh toán',
//                                   style: TextStyle(
//                                       color: AppTheme.successColor,
//                                       fontWeight: FontWeight.w700),
//                                 ),
//                                 Text(
//                                   dateFmt.format(inv.paidAt!),
//                                   style: const TextStyle(
//                                       color: AppTheme.textSecondary,
//                                       fontSize: 12),
//                                 ),
//                                 if (inv.paymentMethod != null)
//                                   Text(
//                                     _methodLabel(inv.paymentMethod!),
//                                     style: const TextStyle(
//                                         color: AppTheme.textSecondary,
//                                         fontSize: 12),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _methodLabel(PaymentMethod m) {
//     switch (m) {
//       case PaymentMethod.cash:
//         return 'Tiền mặt';
//       case PaymentMethod.transfer:
//         return 'Chuyển khoản';
//       case PaymentMethod.momo:
//         return 'Ví MoMo';
//       case PaymentMethod.vnpay:
//         return 'VNPay';
//     }
//   }
// }

// class _InfoCard extends StatelessWidget {
//   final List<Widget> children;
//   const _InfoCard({required this.children});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 2))
//         ],
//       ),
//       child: Column(children: children),
//     );
//   }
// }

// class _InfoRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color? valueColor;
//   const _InfoRow(
//       {required this.icon,
//       required this.label,
//       required this.value,
//       this.valueColor});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: AppTheme.textHint),
//           const SizedBox(width: 8),
//           Text(label,
//               style: const TextStyle(
//                   color: AppTheme.textSecondary, fontSize: 13)),
//           const Spacer(),
//           Text(value,
//               style: TextStyle(
//                   fontWeight: FontWeight.w700,
//                   color: valueColor ?? AppTheme.textPrimary,
//                   fontSize: 13)),
//         ],
//       ),
//     );
//   }
// }

// class _DetailSection extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final String title;
//   final double prevReading;
//   final double currReading;
//   final double used;
//   final double unitPrice;
//   final double total;
//   final String unit;
//   final NumberFormat fmt;
//   const _DetailSection({
//     required this.icon,
//     required this.color,
//     required this.title,
//     required this.prevReading,
//     required this.currReading,
//     required this.used,
//     required this.unitPrice,
//     required this.total,
//     required this.unit,
//     required this.fmt,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: color.withOpacity(0.2)),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 2))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: color, size: 18),
//               ),
//               const SizedBox(width: 8),
//               Text(title,
//                   style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       color: color,
//                       fontSize: 14)),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _ReadRow(label: 'Chỉ số cũ', value: '${fmt.format(prevReading)} $unit'),
//               const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textHint),
//               _ReadRow(label: 'Chỉ số mới', value: '${fmt.format(currReading)} $unit'),
//               _ReadRow(label: 'Tiêu thụ', value: '${fmt.format(used)} $unit', bold: true),
//             ],
//           ),
//           const Divider(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text('${fmt.format(used)} $unit × ${fmt.format(unitPrice)}đ/$unit',
//                   style: const TextStyle(
//                       fontSize: 12, color: AppTheme.textSecondary)),
//               Text('${fmt.format(total)}đ',
//                   style: TextStyle(
//                       fontWeight: FontWeight.w800,
//                       fontSize: 16,
//                       color: color)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ReadRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool bold;
//   const _ReadRow(
//       {required this.label, required this.value, this.bold = false});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(label,
//             style: const TextStyle(
//                 fontSize: 10, color: AppTheme.textHint)),
//         const SizedBox(height: 2),
//         Text(value,
//             style: TextStyle(
//                 fontSize: 12,
//                 fontWeight:
//                     bold ? FontWeight.w800 : FontWeight.w600,
//                 color: bold
//                     ? AppTheme.textPrimary
//                     : AppTheme.textSecondary)),
//       ],
//     );
//   }
// }

// class _PaymentMethodPicker extends StatefulWidget {
//   final String invoiceId;
//   const _PaymentMethodPicker({required this.invoiceId});
//   @override
//   State<_PaymentMethodPicker> createState() => _PaymentMethodPickerState();
// }

// class _PaymentMethodPickerState extends State<_PaymentMethodPicker> {
//   PaymentMethod _selected = PaymentMethod.transfer;

//   static const _methods = [
//     (PaymentMethod.cash, '💵 Tiền mặt', Icons.payments_outlined),
//     (PaymentMethod.transfer, '🏦 Chuyển khoản', Icons.account_balance_outlined),
//     (PaymentMethod.momo, '💜 MoMo', Icons.phone_android_outlined),
//     (PaymentMethod.vnpay, '🔴 VNPay', Icons.credit_card_outlined),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ...(_methods.map((m) {
//           final method = m.$1;
//           final label = m.$2;
//           final icon = m.$3;
//           final selected = _selected == method;
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: GestureDetector(
//               onTap: () => setState(() => _selected = method),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color:
//                       selected ? AppTheme.primary.withOpacity(0.06) : Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: selected
//                         ? AppTheme.primary
//                         : const Color(0xFFE2E8F0),
//                     width: selected ? 2 : 1,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(icon,
//                         color: selected
//                             ? AppTheme.primary
//                             : AppTheme.textHint),
//                     const SizedBox(width: 12),
//                     Text(label,
//                         style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: selected
//                                 ? AppTheme.primary
//                                 : AppTheme.textPrimary)),
//                     const Spacer(),
//                     if (selected)
//                       const Icon(Icons.check_circle,
//                           color: AppTheme.primary, size: 20),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         })),
//         const SizedBox(height: 12),
//         ElevatedButton.icon(
//           onPressed: () async {
//             final ok = await showConfirmSheet<bool>(
//               context,
//               title: 'Xác nhận đã thanh toán',
//               subtitle:
//                   'Chủ trọ sẽ xác nhận sau khi nhận được thanh toán.',
//               confirmLabel: 'Gửi xác nhận',
//             );
//             if (ok == true && context.mounted) {
//               await context
//                   .read<InvoiceProvider>()
//                   .reportPayment(widget.invoiceId, _selected);
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text(
//                         '✅ Đã gửi xác nhận, chờ chủ trọ duyệt!'),
//                     backgroundColor: AppTheme.successColor,
//                   ),
//                 );
//               }
//             }
//           },
//           icon: const Icon(Icons.send_outlined),
//           label: const Text('Xác nhận đã thanh toán'),
//         ),
//       ],
//     );
//   }
// }
