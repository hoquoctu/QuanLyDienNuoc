import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceConfigModel {
  final String id;
  final String ownerId;

  final double electricPrice;
  final double waterPrice;

  final Timestamp updatedAt;

  ServiceConfigModel({
    required this.id,
    required this.ownerId,
    required this.electricPrice,
    required this.waterPrice,
    required this.updatedAt,
  });

  factory ServiceConfigModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    return ServiceConfigModel(
      id: doc.id,
      ownerId: map['owner_id'],
      electricPrice: (map['electricPrice'] ?? 3500).toDouble(),
      waterPrice: (map['waterPrice'] ?? 15000).toDouble(),
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'electricPrice': electricPrice,
      'waterPrice': waterPrice,
      'updatedAt': Timestamp.now(),
    };
  }
}
