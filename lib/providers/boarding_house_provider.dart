import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quanlydiennc_app/services/manager/boarding_house_service.dart';
import 'package:quanlydiennc_app/models/boarding_house_model.dart';
import 'package:quanlydiennc_app/models/bh_room_model.dart';

class BoardingHouseProvider extends ChangeNotifier {
  final _svc = BoardingHouseService.instance;

  List<BoardingHouseModel> _bhList = [];
  // key = bhId, value = danh sách phòng
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

  // ── Khởi tạo khi đăng nhập ─────────────────────────────────────────────
  void initForOwner(String ownerUid) {
    _dispose();
    _loading = true;
    notifyListeners();

    _bhSub = _svc.streamBhByOwner(ownerUid).listen(
      (list) {
        _bhList = list;
        _loading = false;
        notifyListeners();
        print("===== BH DATA =====");
        print(list);
        // Subscribe phòng cho từng dãy mới
        final newIds = list.map((b) => b.bhId).toSet();
        final oldIds = _roomSubs.keys.toSet();

        // Hủy sub của dãy đã bị xóa
        for (final id in oldIds.difference(newIds)) {
          _roomSubs[id]?.cancel();
          _roomSubs.remove(id);
          _roomMap.remove(id);
        }

        // Thêm sub cho dãy mới
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

  // ── CRUD dãy trọ ──────────────────────────────────────────────────────
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
        description: description,
      );

  Future<String?> updateBh(
    String bhId, {
    required String name,
    required String address,
    String? description,
  }) =>
      _svc.updateBoardingHouse(bhId,
          name: name, address: address, description: description);

  Future<String?> deleteBh(String bhId) async {
    // Kiểm tra còn phòng occupied không
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

  Future<String?> deleteRoom(String roomId, BhRoomStatus status) async {
    if (status == BhRoomStatus.occupied) return 'Phòng đang có người thuê!';
    return _svc.deleteRoom(roomId);
  }

  // ── Cleanup khi logout ────────────────────────────────────────────────
  void _dispose() {
    _bhSub?.cancel();
    for (final sub in _roomSubs.values) {
      sub.cancel();
    }
    _roomSubs.clear();
    _roomMap.clear();
    _bhList = [];
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
