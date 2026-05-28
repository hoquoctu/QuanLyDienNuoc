import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanlydiennc_app/models/bill_model.dart';
import 'package:quanlydiennc_app/models/notification_model.dart';
import 'package:quanlydiennc_app/models/payment_model.dart';
import 'package:quanlydiennc_app/services/manager/notification_service.dart';

class PaymentService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────── OWNER CONFIRM PAID + TẠO PAYMENT ─────────────────

  static Future<String?> ownerConfirmAndCreatePayment({
    required BillModel bill,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Tạo payment record từ bill
      final paymentRef = _db.collection('payments').doc();
      batch.set(paymentRef, {
        'id_bill': _db.doc('bills/${bill.id}'),
        'id_owner': _db.doc('users/$ownerId'),
        'id_tenant': bill.idTenant,
        'owner_name': ownerName,
        'tenant_name': bill.nameTenant,
        'room_number': bill.roomNumberName,
        'method': bill.method,
        'transferImage': bill.transfeImage,
        'total': bill.total,
        'month': bill.month,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Update bill: status paid + xóa imageTransfer & method
      final billRef = _db.collection('bills').doc(bill.id);
      batch.update(billRef, {
        'status': _db.doc('status/paid'),
        'transferImage': FieldValue.delete(),
        'method': FieldValue.delete(),
        'updated_at': Timestamp.now(),
      });

      await batch.commit();
      return null;
    } catch (e) {
      return 'Xác nhận thanh toán thất bại: $e';
    }
  }

// ───────────────── OWNER REJECT PAYMENT ─────────────────

  static Future<String?> ownerRejectPayment({
    required BillModel bill,
    required String ownerId,
  }) async {
    try {
      final batch = _db.batch();

      // Revert bill về unpaid + xóa imageTransfer & method
      final billRef = _db.collection('bills').doc(bill.id);
      batch.update(billRef, {
        'status': _db.doc('status/unpaid'),
        'transferImage': FieldValue.delete(),
        'method': FieldValue.delete(),
        'updated_at': Timestamp.now(),
      });

      await batch.commit();

      // Notification cho tenant
      await NotificationService.instance.createNotification(
        receiverId: bill.idTenant.id,
        senderId: ownerId,
        type: NotificationType.payment,
        content:
            'Phòng ${bill.roomNumberName} - Tháng ${bill.month}: Giao dịch không thành công. Vui lòng kiểm tra lại phiên giao dịch.',
      );

      return null;
    } catch (e) {
      return 'Từ chối thanh toán thất bại: $e';
    }
  }

// ───────────────── STREAM PAYMENTS BY OWNER ─────────────────

  static Stream<List<PaymentModel>> streamPaymentsByOwner({
    required String ownerId,
    required String month,
  }) {
    return _db
        .collection('payments')
        .where('id_owner', isEqualTo: _db.doc('users/$ownerId'))
        .where('month', isEqualTo: month)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PaymentModel.fromDoc(d)).toList());
  }
}
