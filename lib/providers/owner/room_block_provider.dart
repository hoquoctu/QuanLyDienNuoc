import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quanlydiennc_app/models/room_block_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RoomBlockProvider extends ChangeNotifier {
  List<RoomBlockModel> _blocks = [];

  static const _key = 'room_blocks';

  List<RoomBlockModel> blocksForManager(String managerId) =>
      _blocks.where((b) => b.managerId == managerId && !b.isDeleted).toList();

  RoomBlockModel? getById(String id) =>
      _blocks.where((b) => b.id == id).firstOrNull;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final list = jsonDecode(json) as List;
      _blocks = list.map((e) => RoomBlockModel.fromMap(e)).toList();
    } else {
      // seed demo
      _blocks = [
        RoomBlockModel(
          id: 'blk001',
          managerId: 'mgr001',
          name: 'Dãy Trọ Bình Minh',
          address: '123 Đường Lê Văn Việt, Quận 9, TP.HCM',
          createdAt: DateTime(2024, 1, 1),
        ),
      ];
      await _save();
    }
    notifyListeners();
  }

  Future<String?> addBlock({
    required String managerId,
    required String name,
    required String address,
  }) async {
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin dãy trọ';
    }
    _blocks.add(RoomBlockModel(
      id: const Uuid().v4(),
      managerId: managerId,
      name: name.trim(),
      address: address.trim(),
      createdAt: DateTime.now(),
    ));
    await _save();
    notifyListeners();
    return null;
  }

  Future<String?> updateBlock(String id,
      {required String name, required String address}) async {
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin';
    }
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return 'Dãy trọ không tồn tại';
    _blocks[idx].name = name.trim();
    _blocks[idx].address = address.trim();
    await _save();
    notifyListeners();
    return null;
  }

  /// Soft-delete (isDelete = true) - chỉ khi không còn người thuê
  Future<String?> deleteBlock(String id) async {
    final idx = _blocks.indexWhere((b) => b.id == id);
    if (idx == -1) return 'Dãy trọ không tồn tại';
    _blocks[idx].isDeleted = true;
    await _save();
    notifyListeners();
    return null;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_blocks.map((b) => b.toMap()).toList()));
  }
}
