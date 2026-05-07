class RoomBlockModel {
  final String id;
  final String managerId;
  String name;
  String address;
  bool isDeleted;
  final DateTime createdAt;

  RoomBlockModel({
    required this.id,
    required this.managerId,
    required this.name,
    required this.address,
    this.isDeleted = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'managerId': managerId,
        'name': name,
        'address': address,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoomBlockModel.fromMap(Map<String, dynamic> m) => RoomBlockModel(
        id: m['id'],
        managerId: m['managerId'],
        name: m['name'],
        address: m['address'],
        isDeleted: m['isDeleted'] ?? false,
        createdAt: DateTime.parse(m['createdAt']),
      );
}
