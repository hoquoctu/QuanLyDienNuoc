import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/room_review_model.dart';
import 'package:quanlydiennc_app/providers/auth_provider.dart';
import 'package:quanlydiennc_app/providers/owner/room_review_provider.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import 'package:quanlydiennc_app/widgets/room_review_widgets.dart';

/// Screen detail phòng dành cho USER:
/// - Xem tất cả đánh giá
/// - Gửi / sửa đánh giá của mình (rating + comment + ảnh)
/// - Mỗi lần thuê chỉ 1 review, có thể edit
class RoomReviewUserScreen extends StatefulWidget {
  final BhRoomModel room;
  final String bhName;

  const RoomReviewUserScreen({
    super.key,
    required this.room,
    required this.bhName,
  });

  @override
  State<RoomReviewUserScreen> createState() => _RoomReviewUserScreenState();
}

class _RoomReviewUserScreenState extends State<RoomReviewUserScreen> {
  final _commentCtrl = TextEditingController();
  double _rating = 0;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _editMode = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context
          .read<RoomReviewProvider>()
          .init(widget.room.bhRoomId, tenantId: user?.uid);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _enterEditMode(RoomReviewModel? existing) {
    setState(() {
      _editMode = true;
      _rating = existing?.rating ?? 0;
      _commentCtrl.text = existing?.comment ?? '';
      _existingImageUrls = List.from(existing?.imageUrls ?? []);
      _newImages = [];
    });
  }

  void _cancelEdit() {
    setState(() {
      _editMode = false;
      _rating = 0;
      _commentCtrl.clear();
      _existingImageUrls = [];
      _newImages = [];
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;
    final total = _existingImageUrls.length + _newImages.length + picked.length;
    if (total > 5) {
      _showSnack('Tối đa 5 ảnh cho mỗi đánh giá', isError: true);
      return;
    }
    setState(() {
      _newImages.addAll(picked.map((x) => File(x.path)));
    });
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _showSnack('Vui lòng chọn số sao', isError: true);
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập nội dung đánh giá', isError: true);
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    final provider = context.read<RoomReviewProvider>();
    final existing = provider.myReview;

    String? err;
    if (existing != null) {
      err = await provider.updateReview(
        roomId: widget.room.bhRoomId,
        reviewId: existing.reviewId,
        tenantId: user.uid,
        rating: _rating,
        comment: _commentCtrl.text,
        existingImageUrls: _existingImageUrls,
        newImageFiles: _newImages,
      );
    } else {
      err = await provider.submitReview(
        roomId: widget.room.bhRoomId,
        tenantId: user.uid,
        tenantName: user.name,
        rating: _rating,
        comment: _commentCtrl.text,
        imageFiles: _newImages,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (err != null) {
      _showSnack(err, isError: true);
    } else {
      _cancelEdit();
      _showSnack('Đã lưu đánh giá!');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomReviewProvider>();
    final user = context.read<AuthProvider>().currentUser;
    final isOwner = user?.isOwner ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đánh giá phòng ${widget.room.bhRoomNumber}'),
            Text(widget.bhName,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _buildError(provider.error!)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Rating summary ────────────────────────────────────
                      _buildSummaryCard(provider),
                      const SizedBox(height: 16),

                      // ── Form đánh giá (chỉ hiện khi phòng đang occupied và không phải chủ trọ) ──
                      if (widget.room.bhRoomStatus == BhRoomStatus.occupied && !isOwner)
                        _buildReviewSection(provider),

                      // ── Danh sách tất cả reviews ──────────────────────────
                      if (provider.reviews.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Tất cả đánh giá',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 12),
                        ...provider.reviews.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ReviewCard(
                              review: r,
                              isOwner: false,
                              onEdit: r.tenantId ==
                                      context
                                          .read<AuthProvider>()
                                          .currentUser
                                          ?.uid
                                  ? () => _enterEditMode(r)
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(RoomReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RatingsSummaryBar(
        average: provider.averageRating,
        count: provider.reviews.length,
      ),
    );
  }

  Widget _buildReviewSection(RoomReviewProvider provider) {
    final myReview = provider.myReview;
    final hasReview = myReview != null;

    // Đã có review và không trong edit mode → hiện review của mình
    if (hasReview && !_editMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đánh giá của bạn',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
              TextButton.icon(
                onPressed: () => _enterEditMode(myReview),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Sửa'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReviewCard(
            review: myReview,
            isOwner: false,
            onEdit: () => _enterEditMode(myReview),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
        ],
      );
    }

    // Chưa có review hoặc đang edit mode → hiện form
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasReview ? 'Chỉnh sửa đánh giá' : 'Viết đánh giá',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Star input
              const Text('Đánh giá',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              StarRatingInput(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
              if (_rating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _ratingLabel(_rating),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                  ),
                ),
              const SizedBox(height: 16),

              // Comment
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét của bạn',
                  hintText: 'Chia sẻ trải nghiệm thuê phòng...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Images
              const Text('Ảnh đính kèm (tối đa 5)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  if (hasReview)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEdit,
                        child: const Text('Hủy'),
                      ),
                    ),
                  if (hasReview) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _submitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.send),
                            label:
                                Text(hasReview ? 'Cập nhật' : 'Gửi đánh giá'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildImagePicker() {
    final allCount = _existingImageUrls.length + _newImages.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing images (từ Firestore)
        ..._existingImageUrls.map((url) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _existingImageUrls.remove(url)),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),

        // New images (chưa upload)
        ..._newImages.map((f) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.file(f, width: 72, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _newImages.remove(f)),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )),

        // Nút thêm ảnh
        if (allCount < 5)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3), width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppTheme.primary, size: 24),
                  SizedBox(height: 2),
                  Text('Thêm',
                      style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _ratingLabel(double r) {
    switch (r.toInt()) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tốt';
      case 5:
        return 'Tuyệt vời!';
      default:
        return '';
    }
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
