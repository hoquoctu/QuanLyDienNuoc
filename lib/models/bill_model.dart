import 'package:cloud_firestore/cloud_firestore.dart';

class UtilityData {
  final double oldNumber;
  final double newNumber;
  final double used;
  final double unitPrice;
  final double total;

  /// cloudinary image url
  final String image;

  const UtilityData({
    required this.oldNumber,
    required this.newNumber,
    required this.used,
    required this.unitPrice,
    required this.total,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'oldNumber': oldNumber,
      'newNumber': newNumber,
      'used': used,
      'unitPrice': unitPrice,
      'total': total,
      'image': image,
    };
  }

  factory UtilityData.fromMap(Map<String, dynamic> map) {
    return UtilityData(
      oldNumber: (map['oldNumber'] ?? 0).toDouble(),
      newNumber: (map['newNumber'] ?? 0).toDouble(),
      used: (map['used'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      image: map['image'] ?? '',
    );
  }
}

class BillModel {
  final String id;

  final DocumentReference idOwner;
  final DocumentReference idRoom;
  final DocumentReference idTenant;

  /// yyyy-MM
  final String month;

  final DocumentReference status;

  final double total;

  final UtilityData electric;
  final UtilityData water;

  final Timestamp createdAt;
  final Timestamp updatedAt;

  const BillModel({
    required this.id,
    required this.idOwner,
    required this.idRoom,
    required this.idTenant,
    required this.month,
    required this.status,
    required this.total,
    required this.electric,
    required this.water,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_owner': idOwner,
      'id_room': idRoom,
      'id_tenant': idTenant,
      'month': month,
      'status': status,
      'total': total,
      'electric': electric.toMap(),
      'water': water.toMap(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BillModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return BillModel(
      id: doc.id,
      idOwner: map['id_owner'],
      idRoom: map['id_room'],
      idTenant: map['id_tenant'],
      month: map['month'] ?? '',
      status: map['status'],
      total: (map['total'] ?? 0).toDouble(),
      electric: UtilityData.fromMap(
        Map<String, dynamic>.from(map['electric'] ?? {}),
      ),
      water: UtilityData.fromMap(
        Map<String, dynamic>.from(map['water'] ?? {}),
      ),
      createdAt: map['created_at'] ?? Timestamp.now(),
      updatedAt: map['updated_at'] ?? Timestamp.now(),
    );
  }
}
