import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/notification_model.dart';

import './manager/notification_service.dart';

class ServiceConfigService {
  static final _db = FirebaseFirestore.instance;

  // ───────────────── GET PRICES ─────────────────

  static Future<Map<String, dynamic>> getPrices(
    String ownerId,
  ) async {
    final snapshot = await _db
        .collection('service_configs')
        .where(
          'owner_id',
          isEqualTo: _db.doc('users/$ownerId'),
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'electricPrice': 3500.0,
        'waterPrice': 15000.0,
      };
    }

    final data = snapshot.docs.first.data();

    return {
      'docId': snapshot.docs.first.id,
      'electricPrice': (data['electricPrice'] ?? 3500).toDouble(),
      'waterPrice': (data['waterPrice'] ?? 15000).toDouble(),
    };
  }

  // ───────────────── UPDATE PRICES ─────────────────

  static Future<String?> updatePrices({
    required String ownerId,
    required double electricPrice,
    required double waterPrice,
  }) async {
    try {
      // lấy config hiện tại
      final configSnap = await _db
          .collection('service_configs')
          .where(
            'owner_id',
            isEqualTo: _db.doc('users/$ownerId'),
          )
          .limit(1)
          .get();

      if (configSnap.docs.isEmpty) {
        return 'Không tìm thấy cấu hình';
      }

      final configDoc = configSnap.docs.first;

      final oldElectric = (configDoc['electricPrice'] ?? 3500).toDouble();

      final oldWater = (configDoc['waterPrice'] ?? 15000).toDouble();

      // update giá
      await configDoc.reference.update({
        'electricPrice': electricPrice,
        'waterPrice': waterPrice,
        'updatedAt': Timestamp.now(),
      });

      // ───────────────── LẤY TOÀN BỘ ROOM ─────────────────

      final bhSnap = await _db
          .collection('boardingHouse')
          .where(
            'owner_id',
            isEqualTo: _db.doc('users/$ownerId'),
          )
          .get();

      if (bhSnap.docs.isEmpty) {
        return null;
      }

      final bhRefs = bhSnap.docs.map((e) => e.reference);

      final roomSnap = await _db
          .collection('room')
          .where(
            'boarding_house',
            whereIn: bhRefs.toList(),
          )
          .get();

      if (roomSnap.docs.isEmpty) {
        return null;
      }

      // ───────────────── TÍNH % ─────────────────

      String electricText = '';
      String waterText = '';

      if (oldElectric != electricPrice) {
        final percent = ((electricPrice - oldElectric) / oldElectric) * 100;

        electricText =
            'Điện ${percent >= 0 ? 'tăng' : 'giảm'} ${percent.abs().toStringAsFixed(0)}%';
      }

      if (oldWater != waterPrice) {
        final percent = ((waterPrice - oldWater) / oldWater) * 100;

        waterText =
            'Nước ${percent >= 0 ? 'tăng' : 'giảm'} ${percent.abs().toStringAsFixed(0)}%';
      }

      final content = [
        electricText,
        waterText,
      ]
          .where(
            (e) => e.isNotEmpty,
          )
          .join(' • ');

      // ───────────────── LẤY TENANT ─────────────────

      final receiverIds = <String>{};

      for (final room in roomSnap.docs) {
        final tenantRef = room['tenant_id'];

        if (tenantRef != null && tenantRef is DocumentReference) {
          receiverIds.add(
            tenantRef.id,
          );
        }
      }

      // ───────────────── GỬI NOTIFICATION ─────────────────

      if (receiverIds.isNotEmpty && content.isNotEmpty) {
        await NotificationService.instance.broadcastNotification(
          receiverIds: receiverIds.toList(),
          senderId: ownerId,
          type: NotificationType.system,
          content: content,
        );
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
