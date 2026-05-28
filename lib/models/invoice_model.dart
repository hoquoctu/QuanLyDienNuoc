enum InvoiceStatus {
  waitingPayment, // chờ thanh toán
  pendingConfirm, // chờ xác nhận (user đã báo trả)
  paid, // đã thanh toán đúng hạn
  paidLate, // đã thanh toán trễ
}

enum PaymentMethod { cash, transfer, momo, vnpay }

class InvoiceModel {
  final String id;
  final String roomId;
  final String roomName;
  final String blockId;
  final String blockName;
  final String blockAddress;
  final String tenantId;
  final String tenantName;

  final double prevElec;
  final double currElec;
  final double prevWater;
  final double currWater;
  final double elecPrice;
  final double waterPrice;

  final String? imagePath;
  final DateTime createdAt;
  final DateTime dueDate;

  InvoiceStatus status;
  PaymentMethod? paymentMethod;
  DateTime? paidAt;

  InvoiceModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.blockId,
    required this.blockName,
    required this.blockAddress,
    required this.tenantId,
    required this.tenantName,
    required this.prevElec,
    required this.currElec,
    required this.prevWater,
    required this.currWater,
    required this.elecPrice,
    required this.waterPrice,
    this.imagePath,
    required this.createdAt,
    required this.dueDate,
    this.status = InvoiceStatus.waitingPayment,
    this.paymentMethod,
    this.paidAt,
  });

  double get elecUsed => currElec - prevElec;
  double get waterUsed => currWater - prevWater;
  double get elecTotal => elecUsed * elecPrice;
  double get waterTotal => waterUsed * waterPrice;
  double get grandTotal => elecTotal + waterTotal;

  Map<String, dynamic> toMap() => {
        'id': id,
        'roomId': roomId,
        'roomName': roomName,
        'blockId': blockId,
        'blockName': blockName,
        'blockAddress': blockAddress,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'prevElec': prevElec,
        'currElec': currElec,
        'prevWater': prevWater,
        'currWater': currWater,
        'elecPrice': elecPrice,
        'waterPrice': waterPrice,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'paymentMethod': paymentMethod?.name,
        'paidAt': paidAt?.toIso8601String(),
      };

  factory InvoiceModel.fromMap(Map<String, dynamic> m) => InvoiceModel(
        id: m['id'],
        roomId: m['roomId'],
        roomName: m['roomName'],
        blockId: m['blockId'],
        blockName: m['blockName'],
        blockAddress: m['blockAddress'],
        tenantId: m['tenantId'],
        tenantName: m['tenantName'],
        prevElec: (m['prevElec'] ?? 0).toDouble(),
        currElec: (m['currElec'] ?? 0).toDouble(),
        prevWater: (m['prevWater'] ?? 0).toDouble(),
        currWater: (m['currWater'] ?? 0).toDouble(),
        elecPrice: (m['elecPrice'] ?? 3500).toDouble(),
        waterPrice: (m['waterPrice'] ?? 15000).toDouble(),
        imagePath: m['imagePath'],
        createdAt: DateTime.parse(m['createdAt']),
        dueDate: DateTime.parse(m['dueDate']),
        status: InvoiceStatus.values.firstWhere((e) => e.name == m['status'],
            orElse: () => InvoiceStatus.waitingPayment),
        paymentMethod: m['paymentMethod'] != null
            ? PaymentMethod.values.firstWhere(
                (e) => e.name == m['paymentMethod'],
                orElse: () => PaymentMethod.cash)
            : null,
        paidAt: m['paidAt'] != null ? DateTime.parse(m['paidAt']) : null,
      );
}
