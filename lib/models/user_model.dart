enum UserRole { manager, user }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final String? avatarPath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.avatarPath,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? password,
    String? avatarPath,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.name,
        'avatarPath': avatarPath,
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        id: m['id'],
        name: m['name'],
        email: m['email'],
        phone: m['phone'],
        password: m['password'],
        role: m['role'] == 'manager' ? UserRole.manager : UserRole.user,
        avatarPath: m['avatarPath'],
      );
}
