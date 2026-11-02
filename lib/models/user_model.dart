class UserModel {
  String id;
  String name;
  String email;
  String phone;
  String role; // 'client' or 'provider'
  String? profileImagePath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.profileImagePath,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profileImagePath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImagePath:
          profileImagePath ?? this.profileImagePath,
    );
  }

  // تحويل UserModel إلى بيانات Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImagePath': profileImagePath ?? '',
    };
  }

  // تحويل بيانات Firestore إلى UserModel
  factory UserModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'client',
      profileImagePath:
          map['profileImagePath'] as String?,
    );
  }
}