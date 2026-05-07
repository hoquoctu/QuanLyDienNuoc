enum RoomStatus {
  empty,      // phòng trống
  pending,    // chờ duyệt
  rented,     // đã cho thuê
  inactive,   // ngưng hoạt động
}

class RoomModel {
  final String id;
  final String blockId;
  String name;
  RoomStatus status;
  String? tenantId;
  String? tenantName;
  String? joinCode;
  DateTime? joinCodeExpiry;
  DateTime? tenantSince;
  bool everRented;
  double lastElecReading;
  double lastWaterReading;

  RoomModel({
    required this.id,
    required this.blockId,
    required this.name,
    this.status = RoomStatus.empty,
    this.tenantId,
    this.tenantName,
    this.joinCode,
    this.joinCodeExpiry,
    this.tenantSince,
    this.everRented = false,
    this.lastElecReading = 0,
    this.lastWaterReading = 0,
  });

  bool get isJoinCodeValid =>
      joinCode != null &&
      joinCodeExpiry != null &&
      DateTime.now().isBefore(joinCodeExpiry!);

  Map<String, dynamic> toMap() => {
        'id': id,
        'blockId': blockId,
        'name': name,
        'status': status.name,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'joinCode': joinCode,
        'joinCodeExpiry': joinCodeExpiry?.toIso8601String(),
        'tenantSince': tenantSince?.toIso8601String(),
        'everRented': everRented,
        'lastElecReading': lastElecReading,
        'lastWaterReading': lastWaterReading,
      };

  factory RoomModel.fromMap(Map<String, dynamic> m) => RoomModel(
        id: m['id'],
        blockId: m['blockId'],
        name: m['name'],
        status: RoomStatus.values.firstWhere((e) => e.name == m['status'],
            orElse: () => RoomStatus.empty),
        tenantId: m['tenantId'],
        tenantName: m['tenantName'],
        joinCode: m['joinCode'],
        joinCodeExpiry: m['joinCodeExpiry'] != null
            ? DateTime.parse(m['joinCodeExpiry'])
            : null,
        tenantSince: m['tenantSince'] != null
            ? DateTime.parse(m['tenantSince'])
            : null,
        everRented: m['everRented'] ?? false,
        lastElecReading: (m['lastElecReading'] ?? 0).toDouble(),
        lastWaterReading: (m['lastWaterReading'] ?? 0).toDouble(),
      );
}
