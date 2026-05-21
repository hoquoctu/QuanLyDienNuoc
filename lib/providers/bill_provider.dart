import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import '../services/manager/bill_service.dart';

class BillProvider extends ChangeNotifier {
  final List<BillModel> _bills = [];
  final List<BillModel> _allBills = [];

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<BillModel> get allBills => _allBills;
  List<BillModel> get bills => _bills;

  // ───────────────── STREAM ─────────────────

  Stream<List<BillModel>> streamBillsByTenant(
    String tenantId,
  ) {
    return BillService.streamBillsByTenant(
      tenantId,
    );
  }

  Stream<List<BillModel>> streamBillsByRoom(
    String roomId,
  ) {
    return BillService.streamBillsByRoom(
      roomId,
    );
  }

  Stream<List<BillModel>> streamBillsByMonth({
    required String ownerId,
    required String month,
  }) {
    return BillService.streamBillsByMonth(
      ownerId: ownerId,
      month: month,
    );
  }

  // ───────────────── CREATE BILL ─────────────────

  Future<String?> createBill({
    required String ownerId,
    required String roomId,
    required String tenantId,
    required String roomNumber,
    required double oldElectric,
    required double newElectric,
    required double electricPrice,
    required String electricImage,
    required double oldWater,
    required double newWater,
    required double waterPrice,
    required String waterImage,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await BillService.createBill(
        ownerId: ownerId,
        roomId: roomId,
        tenantId: tenantId,
        roomNumber: roomNumber,
        oldElectric: oldElectric,
        newElectric: newElectric,
        electricPrice: electricPrice,
        electricImage: electricImage,
        oldWater: oldWater,
        newWater: newWater,
        waterPrice: waterPrice,
        waterImage: waterImage,
      );

      return result;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────── TENANT CONFIRM PAID ─────────────────

  Future<String?> userConfirmPaid({
    required String billId,
    required String ownerId,
    required String tenantId,
    required String tenantName,
    required String roomNumber,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await BillService.userConfirmPaid(
        billId: billId,
        ownerId: ownerId,
        tenantId: tenantId,
        tenantName: tenantName,
        roomNumber: roomNumber,
      );

      return result;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────── OWNER CONFIRM PAID ─────────────────

  Future<String?> ownerConfirm({
    required BillModel bill,
    required String statusKey,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await BillService.ownerConfirm(
        bill: bill,
        statusKey: statusKey,
        ownerId: ownerId,
        ownerName: ownerName,
      );

      return result;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────── LOCAL STATE ─────────────────

  void setBills(
    List<BillModel> data,
  ) {
    _bills
      ..clear()
      ..addAll(data);

    notifyListeners();
  }

  void clearBills() {
    _bills.clear();
    notifyListeners();
  }

  // ───────────────── FILTER ─────────────────

  List<BillModel> getBillsByMonth(
    String month,
  ) {
    return _bills.where((e) => e.month == month).toList();
  }

  List<BillModel> getBillsByRoom(
    String roomId,
  ) {
    return _bills.where((e) => e.idRoom.id == roomId).toList();
  }

  List<BillModel> getBillsByTenant(
    String tenantId,
  ) {
    return _bills.where((e) => e.idTenant.id == tenantId).toList();
  }

  // ───────────────── TOTAL ─────────────────

  double get totalRevenue {
    double total = 0;

    for (final bill in _bills) {
      total += bill.total;
    }

    return total;
  }

  double revenueByMonth(
    String month,
  ) {
    double total = 0;

    final monthBills = getBillsByMonth(month);

    for (final bill in monthBills) {
      total += bill.total;
    }

    return total;
  }
}
