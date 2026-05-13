import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  system,
  payment,
  room,
}

class NotificationModel {
  final String notifId;

  final String content;

  final NotificationType type;

  final String? senderId;

  final DateTime createdAt;

  const NotificationModel({
    required this.notifId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.senderId,
  });

  factory NotificationModel.fromDoc(
    DocumentSnapshot doc,
  ) {
    final d = doc.data() as Map<String, dynamic>;

    String? senderId;

    final senderRef = d['sender_id'];

    if (senderRef is DocumentReference) {
      senderId = senderRef.id;
    }

    return NotificationModel(
      notifId: doc.id,
      content: d['content'] ?? '',
      type: _typeFromString(
        d['type'] ?? '',
      ),
      senderId: senderId,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore(
    FirebaseFirestore db,
  ) {
    return {
      'content': content,
      'type': _typeToString(type),
      'sender_id': senderId != null ? db.doc('users/$senderId') : null,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  static NotificationType _typeFromString(
    String s,
  ) {
    switch (s) {
      case 'payment':
        return NotificationType.payment;

      case 'room':
        return NotificationType.room;

      default:
        return NotificationType.system;
    }
  }

  static String _typeToString(
    NotificationType t,
  ) {
    switch (t) {
      case NotificationType.system:
        return 'system';

      case NotificationType.payment:
        return 'payment';

      case NotificationType.room:
        return 'room';
    }
  }
}

class NotificationReceiverModel {
  final String itemId;

  final String receiverId;

  final bool isRead;

  const NotificationReceiverModel({
    required this.itemId,
    required this.receiverId,
    required this.isRead,
  });

  factory NotificationReceiverModel.fromDoc(
    DocumentSnapshot doc,
  ) {
    final d = doc.data() as Map<String, dynamic>;

    final receiverRef = d['receiver_id'] as DocumentReference;

    return NotificationReceiverModel(
      itemId: doc.id,
      receiverId: receiverRef.id,
      isRead: d['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore(
    FirebaseFirestore db,
  ) {
    return {
      'receiver_id': db.doc(
        'users/$receiverId',
      ),
      'is_read': isRead,
    };
  }
}
