import 'package:cloud_firestore/cloud_firestore.dart';

class RoomReviewModel {
  final String reviewId;
  final String roomId;
  final String tenantId;
  final String tenantName;
  final double rating; // 1.0 – 5.0
  final String comment;
  final List<String> imageUrls; // URL ảnh đính kèm
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomReviewModel({
    required this.reviewId,
    required this.roomId,
    required this.tenantId,
    required this.tenantName,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // ── Từ Firestore subcollection doc ────────────────────────────────────────
  factory RoomReviewModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // tenant_id: DocumentReference|String
    final tenantRef = d['tenant_id'];
    String tenantId = '';
    if (tenantRef is DocumentReference) {
      tenantId = tenantRef.id;
    } else if (tenantRef is String) {
      tenantId = tenantRef.split('/').last;
    }

    return RoomReviewModel(
      reviewId: doc.id,
      roomId: d['room_id'] ?? '',
      tenantId: tenantId,
      tenantName: d['tenant_name'] ?? '',
      rating: (d['rating'] ?? 0).toDouble(),
      comment: d['comment'] ?? '',
      imageUrls: List<String>.from(d['image_urls'] ?? []),
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  // ── Ghi lên Firestore ──────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore(FirebaseFirestore db, String roomId) => {
        'room_id': roomId,
        'tenant_id': db.doc('users/$tenantId'),
        'tenant_name': tenantName,
        'rating': rating,
        'comment': comment,
        'image_urls': imageUrls,
        'created_at': Timestamp.fromDate(createdAt),
        'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  RoomReviewModel copyWith({
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? updatedAt,
  }) {
    return RoomReviewModel(
      reviewId: reviewId,
      roomId: roomId,
      tenantId: tenantId,
      tenantName: tenantName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
