// models/payment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final DocumentReference idBill;
  final DocumentReference idOwner;
  final DocumentReference idTenant;
  final String ownerName; // snapshot tránh null khi xóa user
  final String tenantName;
  final String roomNumber;
  final String method;
  final String transferImage;
  final double total;
  final String month;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.idBill,
    required this.idOwner,
    required this.idTenant,
    required this.ownerName,
    required this.tenantName,
    required this.roomNumber,
    required this.method,
    required this.transferImage,
    required this.total,
    required this.month,
    required this.createdAt,
  });

  factory PaymentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      idBill: d['id_bill'] as DocumentReference,
      idOwner: d['id_owner'] as DocumentReference,
      idTenant: d['id_tenant'] as DocumentReference,
      ownerName: d['owner_name'] ?? '',
      tenantName: d['tenant_name'] ?? '',
      roomNumber: d['room_number'] ?? '',
      method: d['method'] ?? '',
      transferImage: d['transferImage'] ?? '',
      total: (d['total'] ?? 0).toDouble(),
      month: d['month'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_bill': idBill,
      'id_owner': idOwner,
      'id_tenant': idTenant,
      'owner_name': ownerName,
      'tenant_name': tenantName,
      'room_number': roomNumber,
      'method': method,
      'transferImage': transferImage,
      'total': total,
      'month': month,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
