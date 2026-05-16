import 'package:cloud_firestore/cloud_firestore.dart';

enum BillStatus {
  unpaid,   // /status/unpaid
  paid,     // /status/paid
  overdue,  // /status/overdue (nếu có)
  pending   // /status/pending
}

class BillItemModel {
  final double oldNumber;
  final double newNumber;
  final double used;
  final double unitPrice;
  final double total;
  final String? image;

  const BillItemModel({
    required this.oldNumber,
    required this.newNumber,
    required this.used,
    required this.unitPrice,
    required this.total,
    this.image,
  });

  factory BillItemModel.fromMap(Map<String, dynamic> m) => BillItemModel(
        oldNumber: (m['oldNumber'] ?? 0).toDouble(),
        newNumber: (m['newNumber'] ?? 0).toDouble(),
        used: (m['used'] ?? 0).toDouble(),
        unitPrice: (m['unitPrice'] ?? 0).toDouble(),
        total: (m['total'] ?? 0).toDouble(),
        image: m['image'],
      );
}

class BillModel {
  final String id;
  final String roomId;
  final String tenantId;
  final String ownerId;
  final String month;       // "2026-05"
  final double total;
  final BillStatus status;
  final BillItemModel electric;
  final BillItemModel water;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BillModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    required this.ownerId,
    required this.month,
    required this.total,
    required this.status,
    required this.electric,
    required this.water,
    required this.createdAt,
    required this.updatedAt,
  });

  // Tháng / năm tiện dụng
  int get monthNum => int.tryParse(month.split('-').last) ?? 0;
  int get yearNum => int.tryParse(month.split('-').first) ?? 0;

  String get monthLabel => 'Tháng $monthNum/$yearNum';

  factory BillModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Parse status từ reference
    final statusRef = d['status'];
    String statusKey = 'unpaid';
    if (statusRef is DocumentReference) {
      statusKey = statusRef.id;
    } else if (statusRef is String) {
      statusKey = statusRef.split('/').last;
    }

    // Parse references → lấy ID
    String roomId = '';
    final roomRef = d['id_room'];
    if (roomRef is DocumentReference) roomId = roomRef.id;

    String tenantId = '';
    final tenantRef = d['id_tenant'];
    if (tenantRef is DocumentReference) tenantId = tenantRef.id;

    String ownerId = '';
    final ownerRef = d['id_owner'];
    if (ownerRef is DocumentReference) ownerId = ownerRef.id;

    return BillModel(
      id: doc.id,
      roomId: roomId,
      tenantId: tenantId,
      ownerId: ownerId,
      month: d['month'] ?? '',
      total: (d['total'] ?? 0).toDouble(),
      status: _statusFromKey(statusKey),
      electric: BillItemModel.fromMap(
          (d['electric'] as Map<String, dynamic>?) ?? {}),
      water: BillItemModel.fromMap(
          (d['water'] as Map<String, dynamic>?) ?? {}),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static BillStatus _statusFromKey(String key) {
    switch (key) {
      case 'paid':
        return BillStatus.paid;
      case 'pending':
        return BillStatus.pending;
      case 'overdue':
        return BillStatus.overdue;
      default:
        return BillStatus.unpaid;
    }
  }
}
