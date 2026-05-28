import 'package:cloud_firestore/cloud_firestore.dart';

enum BillStatus {
  unpaid, // /status/unpaid
  paid, // /status/paid
  overdue, // /status/overdue (nếu có)
  pending // /status/pending
}

/// Model dãy trọ — map đúng collection `boardingHouse` trên Firestore
/// Field owner_id dùng reference path /users/{uid}
class BoardingHouseModel {
  final String bhId; // Firestore document ID
  final String ownerId; // UID của chủ trọ (extracted từ reference)
  String bhName;
  String bhAddress;
  String bhDescription;
  final DateTime bhCreatedAt;

  BoardingHouseModel({
    required this.bhId,
    required this.ownerId,
    required this.bhName,
    required this.bhAddress,
    this.bhDescription = '',
    required this.bhCreatedAt,
  });

  // ── Từ Firestore doc ────────────────────────────────────────────────────
  factory BoardingHouseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // owner_id được lưu dạng DocumentReference: /users/{uid}
    final ownerRef = d['owner_id'];
    String ownerId = '';
    if (ownerRef is DocumentReference) {
      ownerId = ownerRef.id;
    } else if (ownerRef is String) {
      ownerId = ownerRef.split('/').last;
    }

    return BoardingHouseModel(
      bhId: doc.id,
      ownerId: ownerId,
      bhName: d['name'] ?? '',
      bhAddress: d['address'] ?? '',
      bhDescription: d['description'] ?? '',
      bhCreatedAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Ghi lên Firestore ───────────────────────────────────────────────────
  Map<String, dynamic> toFirestore(FirebaseFirestore db) => {
        'name': bhName,
        'address': bhAddress,
        'description': bhDescription,
        'owner_id': db.doc('users/$ownerId'),
        'created_at': Timestamp.fromDate(bhCreatedAt),
      };

  // ── Local map (cache nếu cần) ───────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'bhId': bhId,
        'ownerId': ownerId,
        'bhName': bhName,
        'bhAddress': bhAddress,
        'bhDescription': bhDescription,
        'bhCreatedAt': bhCreatedAt.toIso8601String(),
      };

  factory BoardingHouseModel.fromMap(Map<String, dynamic> m) =>
      BoardingHouseModel(
        bhId: m['bhId'] ?? '',
        ownerId: m['ownerId'] ?? '',
        bhName: m['bhName'] ?? '',
        bhAddress: m['bhAddress'] ?? '',
        bhDescription: m['bhDescription'] ?? '',
        bhCreatedAt: DateTime.parse(
            m['bhCreatedAt'] ?? DateTime.now().toIso8601String()),
      );
}
