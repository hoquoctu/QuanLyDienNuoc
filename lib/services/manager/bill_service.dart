import 'package:cloud_firestore/cloud_firestore.dart';

import '../status_service.dart';
import 'notification_service.dart';
import '../../models/payment_model.dart';
import '../../models/notification_model.dart';
import '../../models/bill_model.dart';
import './payment_service.dart';

class BillService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────── CREATE BILL ─────────────────

  static Future<String?> createBill({
    required String ownerId,
    required String roomId,
    required String tenantId,
    required double oldElectric,
    required double newElectric,
    required double electricPrice,
    required String electricImage,
    required double oldWater,
    required double newWater,
    required double waterPrice,
    required String waterImage,
    required String roomNumber,
  }) async {
    try {
      // check bill tháng hiện tại
      final now = DateTime.now();

      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final roomRef = _db.doc('room/$roomId');

      final existBill = await _db
          .collection('bills')
          .where('id_room', isEqualTo: roomRef)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (existBill.docs.isNotEmpty) {
        return 'Phòng đã có hóa đơn tháng này';
      }

      // status unpaid
      final unpaidStatus = _db.doc('status/unpaid');

      // tính điện nước
      final electricUsed = newElectric - oldElectric;
      final waterUsed = newWater - oldWater;

      final electricTotal = electricUsed * electricPrice;
      final waterTotal = waterUsed * waterPrice;

      final total = electricTotal + waterTotal;

      // tạo doc trước để lấy id
      final billRef = _db.collection('bills').doc();

      final bill = BillModel(
        id: billRef.id,
        idOwner: _db.doc('users/$ownerId'),
        idRoom: roomRef,
        idTenant: _db.doc('users/$tenantId'),
        month: month,
        roomNumberName: roomNumber,
        nameTenant: await _db
            .collection('users')
            .doc(tenantId)
            .get()
            .then((value) => value.data()!['name']),
        status: unpaidStatus,
        total: total,
        electric: UtilityData(
          oldNumber: oldElectric,
          newNumber: newElectric,
          used: electricUsed,
          unitPrice: electricPrice,
          total: electricTotal,
          image: electricImage,
        ),
        water: UtilityData(
          oldNumber: oldWater,
          newNumber: newWater,
          used: waterUsed,
          unitPrice: waterPrice,
          total: waterTotal,
          image: waterImage,
        ),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

// create bill
      await billRef.set(
        bill.toMap(),
      );
      // notification cho tenant
      await NotificationService.instance.createNotification(
        receiverId: tenantId,
        senderId: ownerId,
        type: NotificationType.payment,
        content:
            'Hóa đơn tháng $month phòng $roomNumber: ${total.toStringAsFixed(0)}đ',
      );

      return null;
    } catch (e) {
      return 'Tạo hóa đơn thất bại: $e';
    }
  }

  // ───────────────── USER REPORT PAID ─────────────────

  static Future<String?> userConfirmPaid({
    required String billId,
    required String ownerId,
    required String tenantId,
    required String tenantName,
    required String roomNumber,
  }) async {
    try {
      final pendingStatus = await StatusService.getStatusRef(
        type: 'payment',
        key: 'pending',
      );

      await _db.collection('bills').doc(billId).update({
        'status': pendingStatus,
        'updated_at': Timestamp.now(),
      });

      // notification owner
      await NotificationService.instance.createNotification(
        receiverId: ownerId,
        senderId: tenantId,
        type: NotificationType.payment,
        content: '$tenantName báo đã thanh toán phòng $roomNumber',
      );

      return null;
    } catch (e) {
      return 'Xác nhận thanh toán thất bại: $e';
    }
  }

  // ───────────────── OWNER CONFIRM PAID ─────────────────

  static Future<String?> ownerConfirm({
    required BillModel bill,
    required String statusKey,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final status = await StatusService.getStatusRef(
        type: 'payment',
        key: statusKey,
      );

      await _db.collection('bills').doc(bill.id).update({
        'status': status,
        'updated_at': Timestamp.now(),
      });

      // chạy ngầm, không await
      if (statusKey == 'paid') {
        PaymentService.ownerConfirmAndCreatePayment(
          bill: bill,
          ownerId: ownerId,
          ownerName: ownerName,
        );
      }

      if (statusKey == 'unpaid') {
        PaymentService.ownerRejectPayment(
          bill: bill,
          ownerId: ownerId,
        );
      }

      return null;
    } catch (e) {
      return 'Duyệt thanh toán thất bại: $e';
    }
  }

  // ───────────────── GET BILL BY MONTH ─────────────────

  static Stream<List<BillModel>> streamBillsByMonth({
    required String ownerId,
    required String month,
  }) {
    return _db
        .collection('bills')
        .where(
          'id_owner',
          isEqualTo: _db.doc('users/$ownerId'),
        )
        .where('month', isEqualTo: month)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((e) => BillModel.fromDoc(e)).toList(),
        );
  }

  // ───────────────── GET ROOM BILLS ─────────────────

  static Stream<List<BillModel>> streamBillsByRoom(
    String roomId,
  ) {
    return _db
        .collection('bills')
        .where(
          'id_room',
          isEqualTo: _db.doc('room/$roomId'),
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((e) => BillModel.fromDoc(e)).toList(),
        );
  }

  // ───────────────── GET TENANT BILLS ─────────────────

  static Stream<List<BillModel>> streamBillsByTenant(
    String tenantId,
  ) {
    return _db
        .collection('bills')
        .where(
          'id_tenant',
          isEqualTo: _db.doc('users/$tenantId'),
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((e) => BillModel.fromDoc(e)).toList(),
        );
  }

// ── THANH TOÁN HÓA ĐƠN ─────────────────────────────────────────────────
  /// Tạo document trong `payments` + cập nhật bill.status → pending
  Future<String?> submitPayment({
    required String billId,
    required String ownerId,
    required String tenantId,
    required String method, // "cash" | "transfer"
    String transferImage = '', // URL ảnh chuyển khoản
  }) async {
    try {
      final batch = _db.batch();

      // 1. Tạo payment document
      final paymentRef = _db.collection('payments').doc();
      batch.set(paymentRef, {
        'id_bill': _db.doc('bills/$billId'),
        'id_owner': _db.doc('users/$ownerId'),
        'id_tenant': _db.doc('users/$tenantId'),
        'method': method,
        'transferImage': transferImage,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Cập nhật bill status → pending + lưu method & ảnh chuyển khoản
      final billRef = _db.collection('bills').doc(billId);
      batch.update(billRef, {
        'status': _db.doc('status/pending'),
        'method': method,
        'transfe_image': transferImage,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return null; // success
    } catch (e) {
      return 'Thanh toán thất bại: $e';
    }
  }

  /// Trả về payment mới nhất của bill (nếu có)
  Future<PaymentModel?> getPaymentByBill(String billId) async {
    try {
      final billRef = _db.doc('bills/$billId');
      print('[PaymentQuery] Tìm payment cho bill: $billId');
      print('[PaymentQuery] billRef path: ${billRef.path}');

      final snap = await _db
          .collection('payments')
          .where('id_bill', isEqualTo: billRef)
          .get();

      print('[PaymentQuery] Kết quả: ${snap.docs.length} documents');

      if (snap.docs.isEmpty) return null;

      // Nếu có nhiều payment, lấy mới nhất (sort client-side)
      if (snap.docs.length > 1) {
        final docs = snap.docs.toList();
        docs.sort((a, b) {
          final aTime = (a.data()['created_at'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          final bTime = (b.data()['created_at'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          return bTime.compareTo(aTime);
        });
        return PaymentModel.fromDoc(docs.first);
      }

      return PaymentModel.fromDoc(snap.docs.first);
    } catch (e) {
      print('[PaymentQuery] Lỗi: $e');
      return null;
    }
  }
}
