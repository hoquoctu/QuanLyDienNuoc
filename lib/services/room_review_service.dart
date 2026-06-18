import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanlydiennc_app/models/room_review_model.dart';
import 'package:quanlydiennc_app/services/cloudinary_service.dart'; // sửa lại path cho đúng với project của m

/// Subcollection path: room/{roomId}/reviews/{reviewId}
class RoomReviewService {
  RoomReviewService._();
  static final RoomReviewService instance = RoomReviewService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference _reviewsRef(String roomId) =>
      _db.collection('room').doc(roomId).collection('reviews');

  // ── Stream danh sách reviews của phòng (mới nhất trước) ──────────────────
  Stream<List<RoomReviewModel>> streamReviews(String roomId) {
    if (roomId.trim().isEmpty) {
      return Stream.value(<RoomReviewModel>[]);
    }
    try {
      return _reviewsRef(roomId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => RoomReviewModel.fromDoc(d)).toList());
    } catch (e) {
      print("Lỗi khởi tạo streamReviews: $e");
      return Stream.value(<RoomReviewModel>[]);
    }
  }

  // ── Lấy review của tenant trong phòng (nếu có) ───────────────────────────
  Future<RoomReviewModel?> getMyReview(String roomId, String tenantId) async {
    final tenantRef = _db.doc('users/$tenantId');
    final snap = await _reviewsRef(roomId)
        .where('tenant_id', isEqualTo: tenantRef)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RoomReviewModel.fromDoc(snap.docs.first);
  }

  // ── Thêm review mới ───────────────────────────────────────────────────────
  Future<String?> addReview({
    required String roomId,
    required String tenantId,
    required String tenantName,
    required double rating,
    required String comment,
    List<File> imageFiles = const [],
  }) async {
    if (comment.trim().isEmpty) return 'Vui lòng nhập nội dung đánh giá';
    if (rating < 1 || rating > 5) return 'Vui lòng chọn số sao';

    try {
      // Upload ảnh trước (qua Cloudinary, folder Room_Zy/comment)
      final imageUrls = await _uploadImages(tenantId, imageFiles);

      final now = DateTime.now();
      final review = RoomReviewModel(
        reviewId: '',
        roomId: roomId,
        tenantId: tenantId,
        tenantName: tenantName,
        rating: rating,
        comment: comment.trim(),
        imageUrls: imageUrls,
        createdAt: now,
      );

      await _reviewsRef(roomId).add(review.toFirestore(_db, roomId));
      return null;
    } catch (e) {
      return 'Gửi đánh giá thất bại: $e';
    }
  }

  // ── Cập nhật review (edit) ─────────────────────────────────────────────────
  Future<String?> updateReview({
    required String roomId,
    required String reviewId,
    required String tenantId,
    required double rating,
    required String comment,
    List<String> existingImageUrls = const [],
    List<File> newImageFiles = const [],
  }) async {
    if (comment.trim().isEmpty) return 'Vui lòng nhập nội dung đánh giá';
    if (rating < 1 || rating > 5) return 'Vui lòng chọn số sao';

    try {
      final newUrls = await _uploadImages(tenantId, newImageFiles);
      final allUrls = [...existingImageUrls, ...newUrls];

      await _reviewsRef(roomId).doc(reviewId).update({
        'rating': rating,
        'comment': comment.trim(),
        'image_urls': allUrls,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Cập nhật đánh giá thất bại: $e';
    }
  }

  // ── Xóa ảnh khỏi review ───────────────────────────────────────────────────
  // Lưu ý: Cloudinary không cho xóa file trực tiếp từ app (cần API secret +
  // signed request, để secret trong app là không an toàn) nên hàm này chỉ gỡ
  // URL khỏi Firestore. Ảnh vẫn còn tồn trên Cloudinary; nếu cần dọn dẹp thật
  // thì phải làm qua backend/Cloud Function gọi Admin API của Cloudinary.
  Future<String?> removeImageFromReview({
    required String roomId,
    required String reviewId,
    required String imageUrl,
    required List<String> currentUrls,
  }) async {
    try {
      final updated = currentUrls.where((u) => u != imageUrl).toList();
      await _reviewsRef(roomId).doc(reviewId).update({
        'image_urls': updated,
        'updated_at': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Xóa ảnh thất bại: $e';
    }
  }

  // ── Tính điểm trung bình ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> getRoomRatingSummary(String roomId) async {
    final snap = await _reviewsRef(roomId).get();
    if (snap.docs.isEmpty) return {'avg': 0.0, 'count': 0};
    final reviews = snap.docs.map((d) => RoomReviewModel.fromDoc(d)).toList();
    final avg =
        reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    return {'avg': avg, 'count': reviews.length};
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────
  Future<List<String>> _uploadImages(String tenantId, List<File> files) async {
    if (files.isEmpty) return [];
    final urls = <String>[];
    for (final file in files) {
      final url = await CloudinaryService.uploadReviewImage(
        imageFile: file,
        tenantId: tenantId,
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
