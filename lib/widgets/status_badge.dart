import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../models/room_model.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final InvoiceStatus? invoiceStatus;
  final RoomStatus? roomStatus;

  const StatusBadge.invoice(this.invoiceStatus, {super.key})
      : roomStatus = null;
  const StatusBadge.room(this.roomStatus, {super.key})
      : invoiceStatus = null;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (invoiceStatus != null) {
      switch (invoiceStatus!) {
        case InvoiceStatus.paid:
          bg = AppTheme.successColor.withOpacity(0.12);
          fg = AppTheme.successColor;
          label = 'Đã thanh toán';
          break;
        case InvoiceStatus.paidLate:
          bg = AppTheme.warningColor.withOpacity(0.12);
          fg = AppTheme.warningColor;
          label = 'Thanh toán trễ';
          break;
        case InvoiceStatus.pendingConfirm:
          bg = AppTheme.primary.withOpacity(0.12);
          fg = AppTheme.primary;
          label = 'Chờ xác nhận';
          break;
        case InvoiceStatus.waitingPayment:
          bg = AppTheme.errorColor.withOpacity(0.12);
          fg = AppTheme.errorColor;
          label = 'Chưa thanh toán';
          break;
      }
    } else {
      switch (roomStatus!) {
        case RoomStatus.rented:
          bg = AppTheme.successColor.withOpacity(0.12);
          fg = AppTheme.successColor;
          label = 'Đã cho thuê';
          break;
        case RoomStatus.pending:
          bg = AppTheme.primary.withOpacity(0.12);
          fg = AppTheme.primary;
          label = 'Chờ duyệt';
          break;
        case RoomStatus.empty:
          bg = AppTheme.textHint.withOpacity(0.15);
          fg = AppTheme.textSecondary;
          label = 'Phòng trống';
          break;
        case RoomStatus.inactive:
          bg = AppTheme.errorColor.withOpacity(0.12);
          fg = AppTheme.errorColor;
          label = 'Ngưng hoạt động';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
