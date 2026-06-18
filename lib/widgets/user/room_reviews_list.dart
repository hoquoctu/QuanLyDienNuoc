import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/room_review_model.dart';
import 'package:quanlydiennc_app/providers/user/bh_room_provider.dart';
import 'package:quanlydiennc_app/screens/owner/room_block/room_review_screen.dart';
import 'package:quanlydiennc_app/services/room_review_service.dart';
import 'package:quanlydiennc_app/theme/app_theme.dart';
import '../room_review_widgets.dart';

class RoomReviewsList extends StatefulWidget {
  final List<BhRoomModel> rooms;

  const RoomReviewsList({
    super.key,
    required this.rooms,
  });

  @override
  State<RoomReviewsList> createState() => _RoomReviewsListState();
}

class _RoomReviewsListState extends State<RoomReviewsList> {
  final Map<String, List<RoomReviewModel>> _reviewsMap = {};
  final List<StreamSubscription> _subscriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant RoomReviewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didRoomsChange(oldWidget.rooms, widget.rooms)) {
      _unsubscribe();
      _subscribe();
    }
  }

  bool _didRoomsChange(List<BhRoomModel> oldList, List<BhRoomModel> newList) {
    if (oldList.length != newList.length) return true;
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].bhRoomId != newList[i].bhRoomId) return true;
    }
    return false;
  }

  void _subscribe() {
    if (widget.rooms.isEmpty) {
      setState(() {
        _loading = false;
        _reviewsMap.clear();
      });
      return;
    }

    _loading = true;
    _reviewsMap.clear();

    for (final room in widget.rooms) {
      final sub = RoomReviewService.instance.streamReviews(room.bhRoomId).listen(
        (reviews) {
          if (!mounted) return;
          setState(() {
            _reviewsMap[room.bhRoomId] = reviews;
            _loading = false;
          });
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
          });
        },
      );
      _subscriptions.add(sub);
    }
  }

  void _unsubscribe() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  List<RoomReviewModel> get _combinedReviews {
    final list = _reviewsMap.values.expand((x) => x).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  BhRoomModel? _findRoom(String roomId) {
    for (final r in widget.rooms) {
      if (r.bhRoomId == roomId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) return const SizedBox.shrink();

    final reviews = _combinedReviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá & Nhận xét',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            if (widget.rooms.length == 1)
              TextButton(
                onPressed: () {
                  final room = widget.rooms.first;
                  final bh = context.read<BhRoomProviderUser>().boardingHouseFor(room.bhId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomReviewUserScreen(
                        room: room,
                        bhName: bh?.bhName ?? 'Dãy trọ',
                      ),
                    ),
                  );
                },
                child: Text(
                  reviews.isEmpty ? 'Viết đánh giá' : 'Xem tất cả',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading && reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.rooms.length > 1
                  ? 'Chưa có đánh giá nào cho các phòng của bạn.'
                  : 'Chưa có đánh giá nào cho phòng này.',
              style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length > 3 ? 3 : reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final room = _findRoom(review.roomId);
              return ReviewCard(
                review: review,
                isOwner: false,
                roomName: room != null ? 'Phòng ${room.bhRoomNumber}' : null,
                onEdit: () {
                  if (room == null) return;
                  final bh = context.read<BhRoomProviderUser>().boardingHouseFor(room.bhId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomReviewUserScreen(
                        room: room,
                        bhName: bh?.bhName ?? 'Dãy trọ',
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
