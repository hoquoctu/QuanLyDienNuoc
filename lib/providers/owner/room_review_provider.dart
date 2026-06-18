import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:quanlydiennc_app/models/room_review_model.dart';
import 'package:quanlydiennc_app/services/room_review_service.dart';

class RoomReviewProvider extends ChangeNotifier {
  final _service = RoomReviewService.instance;

  List<RoomReviewModel> _reviews = [];
  RoomReviewModel? _myReview;
  bool _loading = false;
  String? _error;
  StreamSubscription? _sub;
  String? _currentRoomId;

  List<RoomReviewModel> get reviews => _reviews;
  RoomReviewModel? get myReview => _myReview;
  bool get loading => _loading;
  String? get error => _error;

  double get averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        _reviews.length;
  }

  // tenantId: truyền uid khi là user side → lọc ra myReview
  // owner side: truyền null
  void init(String roomId, {String? tenantId}) {
    if (_currentRoomId == roomId) return;
    _currentRoomId = roomId;
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _service.streamReviews(roomId).listen(
      (list) {
        _reviews = list;
        _myReview = tenantId != null
            ? list.where((r) => r.tenantId == tenantId).firstOrNull
            : null;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Không tải được đánh giá: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<String?> submitReview({
    required String roomId,
    required String tenantId,
    required String tenantName,
    required double rating,
    required String comment,
    List<File> imageFiles = const [],
  }) async {
    if (_myReview != null) {
      return updateReview(
        roomId: roomId,
        reviewId: _myReview!.reviewId,
        tenantId: tenantId,
        rating: rating,
        comment: comment,
        existingImageUrls: _myReview!.imageUrls,
        newImageFiles: imageFiles,
      );
    }
    return _service.addReview(
      roomId: roomId,
      tenantId: tenantId,
      tenantName: tenantName,
      rating: rating,
      comment: comment,
      imageFiles: imageFiles,
    );
  }

  Future<String?> updateReview({
    required String roomId,
    required String reviewId,
    required String tenantId,
    required double rating,
    required String comment,
    List<String> existingImageUrls = const [],
    List<File> newImageFiles = const [],
  }) async {
    return _service.updateReview(
      roomId: roomId,
      reviewId: reviewId,
      tenantId: tenantId,
      rating: rating,
      comment: comment,
      existingImageUrls: existingImageUrls,
      newImageFiles: newImageFiles,
    );
  }

  Future<String?> removeImage({
    required String roomId,
    required String reviewId,
    required String imageUrl,
  }) async {
    if (_myReview == null) return 'Không tìm thấy đánh giá';
    return _service.removeImageFromReview(
      roomId: roomId,
      reviewId: reviewId,
      imageUrl: imageUrl,
      currentUrls: _myReview!.imageUrls,
    );
  }

  void reset() {
    _sub?.cancel();
    _reviews = [];
    _myReview = null;
    _loading = false;
    _error = null;
    _currentRoomId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
