import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String billId;
  final String ownerId;
  final String tenantId;
  final String method; // "cash" | "transfer"
  final String transferImage; // URL ảnh chuyển khoản (rỗng nếu cash)
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.billId,
    required this.ownerId,
    required this.tenantId,
    required this.method,
    required this.transferImage,
    required this.createdAt,
  });

  factory PaymentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    String billId = '';
    final billRef = d['id_bill'];
    if (billRef is DocumentReference) billId = billRef.id;

    String ownerId = '';
    final ownerRef = d['id_owner'];
    if (ownerRef is DocumentReference) ownerId = ownerRef.id;

    String tenantId = '';
    final tenantRef = d['id_tenant'];
    if (tenantRef is DocumentReference) tenantId = tenantRef.id;

    return PaymentModel(
      id: doc.id,
      billId: billId,
      ownerId: ownerId,
      tenantId: tenantId,
      method: d['method'] ?? 'cash',
      transferImage: d['transferImage'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Tạo map để ghi lên Firestore
  Map<String, dynamic> toFirestore(FirebaseFirestore db) => {
        'id_bill': db.doc('bills/$billId'),
        'id_owner': db.doc('users/$ownerId'),
        'id_tenant': db.doc('users/$tenantId'),
        'method': method,
        'transferImage': transferImage,
        'created_at': FieldValue.serverTimestamp(),
      };
}
