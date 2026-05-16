import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/bh_room_model.dart';
import '../models/boarding_house_model.dart';
import '../services/manager/boarding_house_service.dart';

/// Provider dành cho USER — stream phòng trọ của họ từ Firestore
/// (theo tenant_id reference) kèm thông tin dãy trọ (boardingHouse)
class BhRoomProvider extends ChangeNotifier {
  final _svc = BoardingHouseService.instance;

  // ── State ────────────────────────────────────────────────────────────────
  BhRoomModel? _room;
  BhRoomModel? _previousRoom; // lưu trạng thái phòng trước đó
  BoardingHouseModel? _boardingHouse;
  bool _loading = false;
  String? _error;
  bool _wasCancelledByOwner = false; // chủ trọ vừa hủy yêu cầu

  BhRoomModel? get room => _room;
  BoardingHouseModel? get boardingHouse => _boardingHouse;
  bool get loading => _loading;
  String? get error => _error;
  bool get wasCancelledByOwner => _wasCancelledByOwner;

  /// Gọi sau khi UI đã hiển thị thông báo hủy
  void clearCancelledFlag() {
    _wasCancelledByOwner = false;
    // không notifyListeners để tránh rebuild thừa
  }

  // ── Streams ──────────────────────────────────────────────────────────────
  StreamSubscription<BhRoomModel?>? _roomSub;
  StreamSubscription<BoardingHouseModel?>? _bhSub;

  String? _currentTenantUid;

  // ── Init cho user ─────────────────────────────────────────────────────
  void initForUser(String tenantUid) {
    if (_currentTenantUid == tenantUid) return; // tránh re-init không cần thiết
    _currentTenantUid = tenantUid;
    _disposeStreams();
    _loading = true;
    _error = null;
    notifyListeners();

    _roomSub = _svc.streamRoomByTenant(tenantUid).listen(
      (room) async {
        // Detect chủ trọ hủy: phòng đang waiting → bỗng mất (null)
        if (_previousRoom?.bhRoomStatus == BhRoomStatus.waiting && room == null) {
          _wasCancelledByOwner = true;
        }
        _previousRoom = _room;
        _room = room;
        _loading = false;

        // Nếu có phòng, subscribe thêm thông tin dãy trọ
        if (room != null && room.bhId.isNotEmpty) {
          _subscribeBh(room.bhId);
        } else {
          _bhSub?.cancel();
          _bhSub = null;
          _boardingHouse = null;
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
    _bhSub?.cancel();
    _bhSub = _svc.streamBoardingHouseById(bhId).listen(
      (bh) {
        _boardingHouse = bh;
        notifyListeners();
      },
      onError: (_) {}, // lỗi nhỏ, bỏ qua
    );
  }

  // ── Join room bằng code ─────────────────────────────────────────────────
  Future<String?> joinRoomByCode(String code, String tenantUid, String tenantName) async {
    // Tìm phòng có code khớp và còn hiệu lực
    try {
      final db = _svc.db;
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
      if (roomData.bhRoomStatus != BhRoomStatus.empty) {
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
    _room = null;
    _previousRoom = null;
    _boardingHouse = null;
    _loading = false;
    _error = null;
    _wasCancelledByOwner = false;
     notifyListeners();
  }

  void _disposeStreams() {
    _roomSub?.cancel();
    _roomSub = null;
    _bhSub?.cancel();
    _bhSub = null;
  }

  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }
}
