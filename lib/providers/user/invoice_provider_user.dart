import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:quanlydiennc_app/models/invoice_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceProviderUser extends ChangeNotifier {
  List<InvoiceModel> _invoices = [];
  double _elecPrice = 3500;
  double _waterPrice = 15000;

  static const _invoicesKey = 'invoices_data';
  static const _pricesKey = 'prices_data';

  double get elecPrice => _elecPrice;
  double get waterPrice => _waterPrice;

  List<InvoiceModel> get allInvoices => List.unmodifiable(_invoices);

  List<InvoiceModel> invoicesForRoom(String roomId) =>
      _invoices.where((i) => i.roomId == roomId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<InvoiceModel> invoicesForTenant(String tenantId) =>
      _invoices.where((i) => i.tenantId == tenantId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<InvoiceModel> invoicesForBlock(String blockId) =>
      _invoices.where((i) => i.blockId == blockId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<InvoiceModel> invoicesForMonth(String blockId, int year, int month) =>
      _invoices
          .where((i) =>
              i.blockId == blockId &&
              i.createdAt.year == year &&
              i.createdAt.month == month)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load prices
    final pricesJson = prefs.getString(_pricesKey);
    if (pricesJson != null) {
      final map = jsonDecode(pricesJson);
      _elecPrice = (map['elec'] ?? 3500).toDouble();
      _waterPrice = (map['water'] ?? 15000).toDouble();
    }

    // Load invoices
    final invoicesJson = prefs.getString(_invoicesKey);
    if (invoicesJson != null) {
      final list = jsonDecode(invoicesJson) as List;
      _invoices = list.map((e) => InvoiceModel.fromMap(e)).toList();
    } else {
      await _saveInvoices();
    }
    notifyListeners();
  }

  Future<void> updatePrices(double elec, double water) async {
    _elecPrice = elec;
    _waterPrice = water;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pricesKey, jsonEncode({'elec': elec, 'water': water}));
    notifyListeners();
  }

  /// User reports payment
  Future<void> reportPayment(String invoiceId, PaymentMethod method) async {
    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx == -1) return;
    _invoices[idx].status = InvoiceStatus.pendingConfirm;
    _invoices[idx].paymentMethod = method;
    await _saveInvoices();
    notifyListeners();
  }

  /// Manager confirms payment
  Future<void> confirmPayment(String invoiceId) async {
    final idx = _invoices.indexWhere((i) => i.id == invoiceId);
    if (idx == -1) return;
    final inv = _invoices[idx];
    final isLate = DateTime.now().isAfter(inv.dueDate);
    _invoices[idx].status =
        isLate ? InvoiceStatus.paidLate : InvoiceStatus.paid;
    _invoices[idx].paidAt = DateTime.now();
    await _saveInvoices();
    notifyListeners();
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _invoicesKey, jsonEncode(_invoices.map((i) => i.toMap()).toList()));
  }
}
