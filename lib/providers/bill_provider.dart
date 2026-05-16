import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import '../services/bill_service.dart';

class BillProvider extends ChangeNotifier {
  final _svc = BillService.instance;

  List<BillModel> _bills = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<BillModel>>? _sub;
  String? _currentTenantUid;

  List<BillModel> get bills => _bills;
  bool get loading => _loading;
  String? get error => _error;

  List<BillModel> get unpaidBills =>
      _bills.where((b) => b.status == BillStatus.unpaid).toList();

  List<BillModel> get pendingBills =>
      _bills.where((b) => b.status == BillStatus.pending).toList();

  List<BillModel> get paidBills =>
      _bills.where((b) => b.status == BillStatus.paid).toList();

  /// Hóa đơn cần xử lý (chưa TT + đang chờ xác nhận)
  List<BillModel> get activeBills =>
      _bills.where((b) => b.status == BillStatus.unpaid || b.status == BillStatus.pending).toList();

  void initForUser(String tenantUid) {
    if (_currentTenantUid == tenantUid) return;
    _currentTenantUid = tenantUid;
    _sub?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _svc.streamBillsByTenant(tenantUid).listen(
      (bills) {
        _bills = bills;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Lỗi tải hóa đơn: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  void reset() {
    _sub?.cancel();
    _sub = null;
    _currentTenantUid = null;
    _bills = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
