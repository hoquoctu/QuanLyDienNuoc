import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';

class BillService {
  BillService._();
  static final BillService instance = BillService._();

  final _db = FirebaseFirestore.instance;

  /// Stream danh sách hóa đơn của tenant, sắp xếp mới nhất trước (client-side)
  Stream<List<BillModel>> streamBillsByTenant(String tenantUid) {
    final tenantRef = _db.doc('users/$tenantUid');
    return _db
        .collection('bills')
        .where('id_tenant', isEqualTo: tenantRef)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => BillModel.fromDoc(d)).toList();
          // Sort mới nhất trước — client-side để tránh cần composite index
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ── THANH TOÁN HÓA ĐƠN ─────────────────────────────────────────────────
  /// Tạo document trong `payments` + cập nhật bill.status → pending
  Future<String?> submitPayment({
    required String billId,
    required String ownerId,
    required String tenantId,
    required String method,       // "cash" | "transfer"
    String transferImage = '',    // URL ảnh chuyển khoản
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

  // ── LẤY THÔNG TIN THANH TOÁN THEO BILL ─────────────────────────────────
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
          final aTime = (a.data()['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (b.data()['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
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

