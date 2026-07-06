class UserModel {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String? businessName;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.businessName,
    this.role = 'cashier',
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['full_name'] as String,
      businessName: map['business_name'] as String?,
      role: map['role'] as String? ?? 'cashier',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password': password,
      'full_name': fullName,
      'business_name': businessName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? businessName,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAdmin => role == 'admin';
}
