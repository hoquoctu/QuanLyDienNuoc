import 'package:flutter/material.dart';
import 'package:quanlydiennc_app/models/room_review_model.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';

// ── Star rating display (read-only) ──────────────────────────────────────────
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i < rating;
          return Icon(
            half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
            color: const Color(0xFFF59E0B),
            size: size,
          );
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.85,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Star rating input (interactive) ──────────────────────────────────────────
class StarRatingInput extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starVal = i + 1.0;
        return GestureDetector(
          onTap: () => onChanged(starVal),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              value >= starVal ? Icons.star : Icons.star_border,
              color: const Color(0xFFF59E0B),
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

// ── Review card (dùng cho cả owner + user list) ───────────────────────────────
class ReviewCard extends StatelessWidget {
  final RoomReviewModel review;
  final bool isOwner; // true = chủ xem, false = user xem
  final VoidCallback? onEdit; // chỉ user mới edit
  final String? roomName; // hiển thị tên phòng nếu có

  const ReviewCard({
    super.key,
    required this.review,
    this.isOwner = false,
    this.onEdit,
    this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    final isEdited = review.updatedAt != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(
                  review.tenantName.isNotEmpty
                      ? review.tenantName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.tenantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (roomName != null && roomName!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roomName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        StarRatingDisplay(
                            rating: review.rating, size: 13, showNumber: false),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(
                              isEdited ? review.updatedAt! : review.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                          ),
                        ),
                        if (isEdited) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '(đã sửa)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textHint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isOwner && onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ],

          // Images
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _showFullImage(ctx, review.imageUrls, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.imageUrls[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showFullImage(
      BuildContext context, List<String> urls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _FullImageViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }
}

// ── Full-screen image viewer ──────────────────────────────────────────────────
class _FullImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullImageViewer({required this.urls, required this.initialIndex});

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(widget.urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Rating summary bar (owner & user detail) ──────────────────────────────────
class RatingsSummaryBar extends StatelessWidget {
  final double average;
  final int count;

  const RatingsSummaryBar({
    super.key,
    required this.average,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có đánh giá nào',
          style: TextStyle(color: AppTheme.textHint, fontSize: 13),
        ),
      );
    }
    return Row(
      children: [
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingDisplay(rating: average, size: 20, showNumber: false),
            const SizedBox(height: 4),
            Text(
              '$count đánh giá',
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
