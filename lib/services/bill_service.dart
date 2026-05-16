import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_model.dart';

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
}
