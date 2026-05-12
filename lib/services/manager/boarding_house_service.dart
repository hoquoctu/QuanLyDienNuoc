import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/boarding_house_model.dart';

class BoardingHouseService {
  BoardingHouseService._();
  static final BoardingHouseService instance = BoardingHouseService._();

  final _db = FirebaseFirestore.instance;

  // ── DÃYT TRỌ ─────────────────────────────────────────────────────────────

  /// Stream realtime danh sách dãy trọ của owner
  Stream<List<BoardingHouseModel>> streamBhByOwner(String ownerUid) {
    final ownerRef = _db.doc('users/$ownerUid');
    print("===== OWNER UID =====");
    print(_db
        .collection('boardingHouse')
        .where('owner_id', isEqualTo: ownerRef)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BoardingHouseModel.fromDoc(d)).toList()));
    return _db
        .collection('boardingHouse')
        .where('owner_id', isEqualTo: ownerRef)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BoardingHouseModel.fromDoc(d)).toList());
  }

  /// Lấy 1 lần (dùng khi cần)
  Future<List<BoardingHouseModel>> fetchBhByOwner(String ownerUid) async {
    final ownerRef = _db.doc('users/$ownerUid');
    final snap = await _db
        .collection('boardingHouse')
        .where('owner_id', isEqualTo: ownerRef)
        .get();
    print("===== BH DATA =====");
    print(snap.docs.map((d) => d.data()).toList());
    return snap.docs.map((d) => BoardingHouseModel.fromDoc(d)).toList();
  }

  /// Thêm dãy trọ mới
  Future<String?> addBoardingHouse({
    required String ownerUid,
    required String name,
    required String address,
    String description = '',
  }) async {
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin dãy trọ';
    }
    try {
      final newBh = BoardingHouseModel(
        bhId: '',
        ownerId: ownerUid,
        bhName: name.trim(),
        bhAddress: address.trim(),
        bhDescription: description.trim(),
        bhCreatedAt: DateTime.now(),
      );
      await _db.collection('boardingHouse').add(newBh.toFirestore(_db));
      return null;
    } catch (e) {
      return 'Thêm dãy trọ thất bại: $e';
    }
  }

  /// Cập nhật dãy trọ
  Future<String?> updateBoardingHouse(
    String bhId, {
    required String name,
    required String address,
    String? description,
  }) async {
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin';
    }
    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        'address': address.trim(),
        if (description != null) 'description': description.trim(),
      };
      await _db.collection('boardingHouse').doc(bhId).update(updates);
      return null;
    } catch (e) {
      return 'Cập nhật thất bại: $e';
    }
  }

  /// Xóa dãy trọ (hard delete — chỉ gọi khi không còn phòng)
  Future<String?> deleteBoardingHouse(String bhId) async {
    try {
      await _db.collection('boardingHouse').doc(bhId).delete();
      return null;
    } catch (e) {
      return 'Xóa thất bại: $e';
    }
  }

  // ── PHÒNG TRỌ ─────────────────────────────────────────────────────────────

  /// Stream realtime phòng của 1 dãy trọ
  Stream<List<BhRoomModel>> streamRoomsByBh(String bhId) {
    final bhRef = _db.doc('boardingHouse/$bhId');
    return _db
        .collection('room')
        .where('boardingHouse_id', isEqualTo: bhRef)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BhRoomModel.fromDoc(d)).toList());
  }

  /// Thêm phòng vào dãy trọ
  Future<String?> addRoom({
    required String bhId,
    required String roomNumber,
  }) async {
    if (roomNumber.trim().isEmpty) return 'Vui lòng nhập số phòng';
    try {
      final newRoom = BhRoomModel(
        bhRoomId: '',
        bhId: bhId,
        bhRoomNumber: roomNumber.trim(),
      );
      await _db.collection('room').add(newRoom.toFirestore(_db));
      return null;
    } catch (e) {
      return 'Thêm phòng thất bại: $e';
    }
  }

  /// Xóa phòng (chỉ khi trạng thái empty)
  Future<String?> deleteRoom(String roomId) async {
    try {
      await _db.collection('room').doc(roomId).delete();
      return null;
    } catch (e) {
      return 'Xóa phòng thất bại: $e';
    }
  }
}
