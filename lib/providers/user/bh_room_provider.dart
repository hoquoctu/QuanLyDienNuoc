import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/bh_room_model.dart';
import '../../models/boarding_house_model.dart';
import '../../services/manager/boarding_house_service.dart';

/// Provider dành cho USER — stream DANH SÁCH phòng trọ từ Firestore
/// (theo tenant_id reference) kèm thông tin dãy trọ (boardingHouse)
class BhRoomProviderUser extends ChangeNotifier {
  final _svc = BoardingHouseService.instance;

  // ── State ────────────────────────────────────────────────────────────────
  List<BhRoomModel> _rooms = [];
  List<BhRoomModel> _previousRooms = [];
  Map<String, BoardingHouseModel> _boardingHouses = {};
  bool _loading = false;
  String? _error;
  bool _wasCancelledByOwner = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  List<BhRoomModel> get rooms => _rooms;

  /// Phòng đang thuê (occupied)
  List<BhRoomModel> get activeRooms =>
      _rooms.where((r) => r.bhRoomStatus == BhRoomStatus.occupied).toList();

  /// Phòng đang chờ xác nhận (waiting)
  List<BhRoomModel> get waitingRooms =>
      _rooms.where((r) => r.bhRoomStatus == BhRoomStatus.waiting).toList();

  /// Có ít nhất 1 phòng occupied?
  bool get hasRoom => activeRooms.isNotEmpty;

  /// Backward compat: phòng đầu tiên (nếu chỉ có 1)
  BhRoomModel? get room => _rooms.isNotEmpty ? _rooms.first : null;

  /// Lấy boardingHouse theo bhId
  BoardingHouseModel? boardingHouseFor(String bhId) => _boardingHouses[bhId];

  /// Backward compat: boardingHouse của phòng đầu tiên
  BoardingHouseModel? get boardingHouse =>
      room != null ? _boardingHouses[room!.bhId] : null;

  bool get loading => _loading;
  String? get error => _error;
  bool get wasCancelledByOwner => _wasCancelledByOwner;

  void clearCancelledFlag() {
    _wasCancelledByOwner = false;
  }

  // ── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription<List<BhRoomModel>>? _roomSub;
  final Map<String, StreamSubscription<BoardingHouseModel?>> _bhSubs = {};

  String? _currentTenantUid;

  // ── Init cho user ─────────────────────────────────────────────────────
  void initForUser(String tenantUid) {
    if (_currentTenantUid == tenantUid) return;
    _currentTenantUid = tenantUid;
    _disposeStreams();
    _loading = true;
    _error = null;
    notifyListeners();

    _roomSub = _svc.streamRoomsByTenant(tenantUid).listen(
      (rooms) {
        // Detect chủ trọ hủy: phòng waiting biến mất
        for (final prev in _previousRooms) {
          if (prev.bhRoomStatus == BhRoomStatus.waiting) {
            final stillExists = rooms.any((r) => r.bhRoomId == prev.bhRoomId);
            if (!stillExists) {
              _wasCancelledByOwner = true;
              break;
            }
          }
        }

        _previousRooms = List.from(_rooms);
        _rooms = rooms;
        _loading = false;

        // Subscribe boarding house info cho mỗi phòng
        final bhIds =
            rooms.map((r) => r.bhId).where((id) => id.isNotEmpty).toSet();
        // Hủy sub cũ không còn cần
        final toRemove =
            _bhSubs.keys.where((id) => !bhIds.contains(id)).toList();
        for (final id in toRemove) {
          _bhSubs[id]?.cancel();
          _bhSubs.remove(id);
          _boardingHouses.remove(id);
        }
        // Subscribe mới
        for (final bhId in bhIds) {
          if (!_bhSubs.containsKey(bhId)) {
            _subscribeBh(bhId);
          }
        }

        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi tải dữ liệu phòng: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  void _subscribeBh(String bhId) {
    _bhSubs[bhId]?.cancel();
    _bhSubs[bhId] = _svc.streamBoardingHouseById(bhId).listen(
      (bh) {
        if (bh != null) {
          _boardingHouses[bhId] = bh;
        } else {
          _boardingHouses.remove(bhId);
        }
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ── Join room bằng code ─────────────────────────────────────────────────
  Future<String?> joinRoomByCode(
      String code, String tenantUid, String tenantName) async {
    try {
      final db = FirebaseFirestore.instance;
      final snap = await db
          .collection('room')
          .where('code', isEqualTo: code.trim())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return 'Mã phòng không hợp lệ hoặc đã hết hạn';

      final doc = snap.docs.first;
      final roomData = BhRoomModel.fromDoc(doc);

      // Kiểm tra code còn hiệu lực
      if (!roomData.isBhRoomCodeValid) return 'Mã phòng đã hết hạn';

      // Kiểm tra phòng còn trống
      if (roomData.bhRoomStatus != BhRoomStatus.available) {
        return 'Phòng này không còn trống';
      }

      final tenantRef = db.doc('users/$tenantUid');

      // Cập nhật phòng: đặt trạng thái pending + gán tenant
      await db.collection('room').doc(doc.id).update({
        'status': db.doc('status/roompending'),
        'tenant_id': tenantRef,
        'tenant_name': tenantName,
        'update_time': Timestamp.fromDate(DateTime.now()),
      });

      return null; // thành công
    } catch (e) {
      return 'Lỗi khi tham gia phòng: $e';
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  void reset() {
    _disposeStreams();
    _currentTenantUid = null;
    _rooms = [];
    _previousRooms = [];
    _boardingHouses = {};
    _loading = false;
    _error = null;
    _wasCancelledByOwner = false;
    notifyListeners();
  }

  void _disposeStreams() {
    _roomSub?.cancel();
    _roomSub = null;
    for (final sub in _bhSubs.values) {
      sub.cancel();
    }
    _bhSubs.clear();
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}
