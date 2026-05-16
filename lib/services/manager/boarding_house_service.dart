import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';
import 'package:quanlydiennc_app/models/boarding_house_model.dart';

class BoardingHouseService {
  BoardingHouseService._();
  static final BoardingHouseService instance = BoardingHouseService._();

  final _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  // ── DÃY TRỌ ──────────────────────────────────────────────────────────────

  Stream<List<BoardingHouseModel>> streamBhByOwner(String ownerUid) {
    final ownerRef = _db.doc('users/$ownerUid');
    return _db
        .collection('boardingHouse')
        .where('owner_id', isEqualTo: ownerRef)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BoardingHouseModel.fromDoc(d)).toList());
  }

  Future<List<BoardingHouseModel>> fetchBhByOwner(String ownerUid) async {
    final ownerRef = _db.doc('users/$ownerUid');
    final snap = await _db
        .collection('boardingHouse')
        .where('owner_id', isEqualTo: ownerRef)
        .get();
    return snap.docs.map((d) => BoardingHouseModel.fromDoc(d)).toList();
  }

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
      await _db.collection('boardingHouse').doc(bhId).update({
        'name': name.trim(),
        'address': address.trim(),
        if (description != null) 'description': description.trim(),
      });
      return null;
    } catch (e) {
      return 'Cập nhật thất bại: $e';
    }
  }

  Future<String?> deleteBoardingHouse(String bhId) async {
    try {
      await _db.collection('boardingHouse').doc(bhId).delete();
      return null;
    } catch (e) {
      return 'Xóa thất bại: $e';
    }
  }

  // ── PHÒNG TRỌ ─────────────────────────────────────────────────────────────

  Stream<List<BhRoomModel>> streamRoomsByBh(String bhId) {
    final bhRef = _db.doc('boardingHouse/$bhId');
    return _db
        .collection('room')
        .where('boarding_house', isEqualTo: bhRef)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BhRoomModel.fromDoc(d)).toList());
  }

  /// Stream tất cả phòng của người thuê (theo tenant_id reference)
  Stream<List<BhRoomModel>> streamRoomsByTenant(String tenantUid) {
    final tenantRef = _db.doc('users/$tenantUid');
    return _db
        .collection('room')
        .where('tenant_id', isEqualTo: tenantRef)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BhRoomModel.fromDoc(d)).toList());
  }

  /// Lấy thông tin dãy trọ theo ID
  Future<BoardingHouseModel?> fetchBoardingHouseById(String bhId) async {
    final doc = await _db.collection('boardingHouse').doc(bhId).get();
    if (!doc.exists) return null;
    return BoardingHouseModel.fromDoc(doc);
  }

  /// Stream thông tin dãy trọ theo ID
  Stream<BoardingHouseModel?> streamBoardingHouseById(String bhId) {
    return _db
        .collection('boardingHouse')
        .doc(bhId)
        .snapshots()
        .map((doc) => doc.exists ? BoardingHouseModel.fromDoc(doc) : null);
  }

  Future<String?> addRoom({
    required String bhId,
    required String roomNumber,
  }) async {
    if (roomNumber.trim().isEmpty) return 'Vui lòng nhập số phòng';
    try {
      final now = DateTime.now();
      final newRoom = BhRoomModel(
        bhRoomId: '',
        bhId: bhId,
        bhRoomNumber: roomNumber.trim(),
        bhRoomUpdateTime: now,
      );
      await _db.collection('room').add(newRoom.toFirestore(_db));
      return null;
    } catch (e) {
      return 'Thêm phòng thất bại: $e';
    }
  }

  Future<String?> deleteRoom(String roomId) async {
    try {
      await _db.collection('room').doc(roomId).delete();
      return null;
    } catch (e) {
      return 'Xóa phòng thất bại: $e';
    }
  }

  // ── TẠO MÃ JOIN CODE ─────────────────────────────────────────────────────

  /// Owner tạo mã cho phòng trống.
  /// Lưu code + time_start vào Firestore.
  /// Client tự tính hết hạn = time_start + 30 phút.
  Future<String?> generateRoomCode(String roomId) async {
    try {
      // Kiểm tra mã cũ còn hiệu lực không — nếu còn thì không tạo lại
      final doc = await _db.collection('room').doc(roomId).get();
      final data = doc.data();
      if (data != null) {
        final timeStart = (data['time_start'] as Timestamp?)?.toDate();
        if (timeStart != null) {
          final expiry = timeStart.add(const Duration(minutes: 30));
          if (DateTime.now().isBefore(expiry)) {
            return 'Mã hiện tại vẫn còn hiệu lực';
          }
        }
      }

      final code = _generateCode();
      final now = DateTime.now();

      await _db.collection('room').doc(roomId).update({
        'code': code,
        'time_start': Timestamp.fromDate(now),
        'update_time': Timestamp.fromDate(now),
      });
      return null;
    } catch (e) {
      return 'Tạo mã thất bại: $e';
    }
  }

  /// Reset mã về null (gọi sau khi mã hết hạn hoặc owner muốn hủy)
  Future<String?> resetRoomCode(String roomId) async {
    try {
      await _db.collection('room').doc(roomId).update({
        'code': null,
        'time_start': null,
        'update_time': Timestamp.fromDate(DateTime.now()),
      });
      return null;
    } catch (e) {
      return 'Reset mã thất bại: $e';
    }
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────

  /// Sinh mã 6 ký tự chữ hoa + số
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
