import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quanlydiennc_app/services/manager/boarding_house_service.dart';
import '../models/boarding_house_model.dart';
import '../models/bh_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoardingHouseProvider extends ChangeNotifier {
  final _svc = BoardingHouseService.instance;

  List<BoardingHouseModel> _bhList = [];
  final Map<String, List<BhRoomModel>> _roomMap = {};

  bool _loading = false;
  String? _error;

  List<BoardingHouseModel> get bhList => List.unmodifiable(_bhList);
  bool get loading => _loading;
  String? get error => _error;

  List<BhRoomModel> roomsOf(String bhId) =>
      List.unmodifiable(_roomMap[bhId] ?? []);

  StreamSubscription<List<BoardingHouseModel>>? _bhSub;
  final Map<String, StreamSubscription<List<BhRoomModel>>> _roomSubs = {};

  // ── Init ───────────────────────────────────────────────────────────────
  void initForOwner(String ownerUid) {
    _disposeStreams();
    _loading = true;
    notifyListeners();

    _bhSub = _svc.streamBhByOwner(ownerUid).listen(
      (list) {
        _bhList = list;
        _loading = false;
        notifyListeners();

        final newIds = list.map((b) => b.bhId).toSet();
        final oldIds = _roomSubs.keys.toSet();

        for (final id in oldIds.difference(newIds)) {
          _roomSubs[id]?.cancel();
          _roomSubs.remove(id);
          _roomMap.remove(id);
        }

        for (final bh in list) {
          if (!_roomSubs.containsKey(bh.bhId)) {
            _roomSubs[bh.bhId] = _svc.streamRoomsByBh(bh.bhId).listen((rooms) {
              _roomMap[bh.bhId] = rooms;
              notifyListeners();
            });
          }
        }
      },
      onError: (e) {
        _error = 'Lỗi tải dữ liệu: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ── CRUD dãy trọ ─────────────────────────────────────────────────────
  Future<String?> addBh({
    required String ownerUid,
    required String name,
    required String address,
    String description = '',
  }) =>
      _svc.addBoardingHouse(
          ownerUid: ownerUid,
          name: name,
          address: address,
          description: description);

  Future<String?> updateBh(
    String bhId, {
    required String name,
    required String address,
    String? description,
  }) =>
      _svc.updateBoardingHouse(bhId,
          name: name, address: address, description: description);

  Future<String?> deleteBh(String bhId) async {
    final rooms = _roomMap[bhId] ?? [];
    final hasOccupied =
        rooms.any((r) => r.bhRoomStatus == BhRoomStatus.occupied);
    if (hasOccupied) return 'Dãy trọ còn người thuê, không thể xóa!';
    return _svc.deleteBoardingHouse(bhId);
  }

  // ── CRUD phòng ────────────────────────────────────────────────────────
  Future<String?> addRoom({
    required String bhId,
    required String roomNumber,
  }) =>
      _svc.addRoom(bhId: bhId, roomNumber: roomNumber);

  Future<String?> deleteRoom(String roomId) async {
    return _svc.deleteRoom(roomId);
  }

  // ── Join code ─────────────────────────────────────────────────────────

  /// Tạo mã mới cho phòng trống.
  /// Stream tự cập nhật UI sau khi Firestore thay đổi.
  Future<String?> generateRoomCode(String roomId) =>
      _svc.generateRoomCode(roomId);

  /// Reset mã về null (hết hạn hoặc owner hủy thủ công).
  Future<String?> resetRoomCode(String roomId) => _svc.resetRoomCode(roomId);

  // ── Cleanup ───────────────────────────────────────────────────────────
  void _disposeStreams() {
    _bhSub?.cancel();
    for (final sub in _roomSubs.values) {
      sub.cancel();
    }
    _roomSubs.clear();
    _roomMap.clear();
    _bhList = [];
  }

  Future<void> updateLastReading({
    required String roomId,
    required double electric,
    required double water,
  }) async {
    await FirebaseFirestore.instance.collection('room').doc(roomId).update({
      'last_electric': electric,
      'last_water': water,
      'updated_at': Timestamp.now(),
    });
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}
