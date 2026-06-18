import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/room_model.dart';

class RoomProvider extends ChangeNotifier {
  List<RoomModel> _rooms = [];
  static const _key = 'rooms_data';

  List<RoomModel> roomsInBlock(String blockId) =>
      _rooms.where((r) => r.blockId == blockId).toList();

  RoomModel? getById(String id) => _rooms.where((r) => r.id == id).firstOrNull;

  /// Returns room tenant is linked to
  RoomModel? roomForTenant(String tenantId) =>
      _rooms.where((r) => r.tenantId == tenantId).firstOrNull;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _rooms = list.map((e) => RoomModel.fromMap(e)).toList();
    }
    notifyListeners();
  }

  Future<void> addRooms(
      String blockId, String prefix, int start, int end) async {
    for (int i = start; i <= end; i++) {
      final name = '$prefix${i.toString().padLeft(2, '0')}';
      _rooms.add(RoomModel(
        id: const Uuid().v4(),
        blockId: blockId,
        name: name,
        status: RoomStatus.empty,
      ));
    }
    await _save();
    notifyListeners();
  }

  /// Generate join code (valid 30 min)
  Future<String> generateJoinCode(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return '';
    final room = _rooms[idx];
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    final code = '${room.name.replaceAll('-', '').toUpperCase()}$rand';
    _rooms[idx].joinCode = code;
    _rooms[idx].joinCodeExpiry =
        DateTime.now().add(const Duration(minutes: 30));
    await _save();
    notifyListeners();
    return code;
  }

  /// User requests to join room using a code
  Future<String?> requestJoinRoom(
      String code, String userId, String userName) async {
    final idx = _rooms.indexWhere((r) => r.joinCode == code);
    if (idx == -1) return 'Mã phòng không hợp lệ hoặc đã hết hạn';
    final room = _rooms[idx];
    if (!room.isJoinCodeValid) return 'Mã phòng đã hết hạn (30 phút)';
    if (room.status != RoomStatus.empty) return 'Phòng này không còn trống';

    // Set to pending, store tenant info
    _rooms[idx].status = RoomStatus.pending;
    _rooms[idx].tenantId = userId;
    _rooms[idx].tenantName = userName;
    await _save();
    notifyListeners();
    return null;
  }

  /// Manager confirms or rejects pending tenant
  Future<void> confirmTenant(String roomId, bool confirm) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    if (confirm) {
      _rooms[idx].status = RoomStatus.rented;
      _rooms[idx].tenantSince = DateTime.now();
      _rooms[idx].everRented = true;
      _rooms[idx].joinCode = null;
      _rooms[idx].joinCodeExpiry = null;
    } else {
      _rooms[idx].status = RoomStatus.empty;
      _rooms[idx].tenantId = null;
      _rooms[idx].tenantName = null;
      _rooms[idx].joinCode = null;
      _rooms[idx].joinCodeExpiry = null;
    }
    await _save();
    notifyListeners();
  }

  /// Deactivate room (soft delete)
  Future<void> deactivateRoom(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    _rooms[idx].status = RoomStatus.inactive;
    await _save();
    notifyListeners();
  }

  /// Reactivate room
  Future<void> reactivateRoom(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    _rooms[idx].status = RoomStatus.empty;
    await _save();
    notifyListeners();
  }

  /// Permanently delete room (only if never rented)
  Future<String?> deleteRoomPermanent(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return 'Không tìm thấy phòng';
    if (_rooms[idx].everRented)
      return 'Phòng đã từng có người thuê, không thể xóa vĩnh viễn';
    _rooms.removeAt(idx);
    await _save();
    notifyListeners();
    return null;
  }

  Future<void> updateLastReadings(
      String roomId, double elec, double water) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    _rooms[idx].lastElecReading = elec;
    _rooms[idx].lastWaterReading = water;
    await _save();
    notifyListeners();
  }

  /// Remove tenant linkage when invoice is finalized
  Future<void> removeTenant(String roomId) async {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    _rooms[idx].status = RoomStatus.empty;
    _rooms[idx].tenantId = null;
    _rooms[idx].tenantName = null;
    _rooms[idx].joinCode = null;
    _rooms[idx].joinCodeExpiry = null;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_rooms.map((r) => r.toMap()).toList()));
  }
}
