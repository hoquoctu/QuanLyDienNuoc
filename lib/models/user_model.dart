import 'package:cloud_firestore/cloud_firestore.dart';

//role: owner (chu tro) | user (nguoi thue)
enum UserRole { owner, user }

class UserModel {
  final String uid; // = Firebase Auth UID = Firestore document ID
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? avatar;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
  });

  // ── Factory từ Firestore doc ────────────────────────────────────────────
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: _roleFromString(data['role']),
      avatar: data['avatar'],
    );
  }

  // ── Factory từ Map thường (SharedPreferences / test) ───────────────────
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: _roleFromString(m['role']),
        avatar: m['avatar'],
      );

  // ── Serialize ───────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name, // 'owner' | 'user'
        'avatar': avatar,
      };

  /// Dùng khi write lên Firestore (không lưu uid vào field, uid = doc ID)
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'avatar': avatar,
      };

  // ── CopyWith ────────────────────────────────────────────────────────────
  UserModel copyWith({
    String? name,
    String? phone,
    String? avatar,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        avatar: avatar ?? this.avatar,
      );

  // ── Helpers ─────────────────────────────────────────────────────────────
  bool get isOwner => role == UserRole.owner;
  bool get isUser => role == UserRole.user;

  static UserRole _roleFromString(dynamic value) {
    if (value == 'owner') return UserRole.owner;
    return UserRole.user;
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, name: $name, email: $email, role: ${role.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}
