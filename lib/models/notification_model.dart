import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  unlinkRequest, // owner gửi yêu cầu hủy liên kết cho tenant
  unlinkAccepted, // tenant xác nhận hủy liên kết
  unlinkRejected, // tenant từ chối hủy liên kết
  priceUpdate, // owner cập nhật giá điện/nước
}

class NotificationModel {
  final String notifId;
  final String receiverId; // userId nhận thông báo (document cha)
  final String? senderId; // userId gửi (owner hoặc tenant)
  final NotificationType type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  // Data tuỳ theo type
  final String? requestId; // dùng cho unlink
  final String? roomId;
  final String? roomNumber;

  const NotificationModel({
    required this.notifId,
    required this.receiverId,
    this.senderId,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.requestId,
    this.roomId,
    this.roomNumber,
  });

  factory NotificationModel.fromDoc(String receiverId, DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final typeStr = d['type'] as String? ?? '';
    final type = _typeFromString(typeStr);

    final senderRef = d['sender_id'];
    String? senderId;
    if (senderRef is DocumentReference) {
      senderId = senderRef.id;
    }

    final roomRef = d['id_room'];
    String? roomId;
    if (roomRef is DocumentReference) {
      roomId = roomRef.id;
    }

    final requestRef = d['id_request'];
    String? requestId;
    if (requestRef is DocumentReference) {
      requestId = requestRef.id;
    }

    return NotificationModel(
      notifId: doc.id,
      receiverId: receiverId,
      senderId: senderId,
      type: type,
      content: d['content'] as String? ?? '',
      isRead: d['is_read'] as bool? ?? false,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestId: requestId,
      roomId: roomId,
      roomNumber: d['room_number'] as String?,
    );
  }

  Map<String, dynamic> toFirestore(FirebaseFirestore db, String receiverId) => {
        'sender_id': senderId != null ? db.doc('users/$senderId') : null,
        'type': _typeToString(type),
        'content': content,
        'is_read': isRead,
        'created_at': Timestamp.fromDate(createdAt),
        if (requestId != null) 'id_request': db.doc('request/$requestId'),
        if (roomId != null) 'id_room': db.doc('room/$roomId'),
        if (roomNumber != null) 'room_number': roomNumber,
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        notifId: notifId,
        receiverId: receiverId,
        senderId: senderId,
        type: type,
        content: content,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        requestId: requestId,
        roomId: roomId,
        roomNumber: roomNumber,
      );

  static NotificationType _typeFromString(String s) {
    switch (s) {
      case 'unlink_request':
        return NotificationType.unlinkRequest;
      case 'unlink_accepted':
        return NotificationType.unlinkAccepted;
      case 'unlink_rejected':
        return NotificationType.unlinkRejected;
      case 'price_update':
        return NotificationType.priceUpdate;
      default:
        return NotificationType.unlinkRequest;
    }
  }

  static String _typeToString(NotificationType t) {
    switch (t) {
      case NotificationType.unlinkRequest:
        return 'unlink_request';
      case NotificationType.unlinkAccepted:
        return 'unlink_accepted';
      case NotificationType.unlinkRejected:
        return 'unlink_rejected';
      case NotificationType.priceUpdate:
        return 'price_update';
    }
  }
}
