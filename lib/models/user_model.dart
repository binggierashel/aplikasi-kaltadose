enum UserRole { owner, petani }

extension UserRoleExt on UserRole {
  String get label => this == UserRole.owner ? 'Owner' : 'Petani';
  String get code => this == UserRole.owner ? 'owner' : 'petani';

  static UserRole fromCode(String? code) {
    return code == 'owner' ? UserRole.owner : UserRole.petani;
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.active,
    required this.phone,
    required this.password,
  });

  final int id;
  final String name;
  final String username;
  final UserRole role;
  final bool active;
  final String phone;
  final String password;

  bool get isOwner => role == UserRole.owner;

  AppUser copyWith({
    int? id,
    String? name,
    String? username,
    UserRole? role,
    bool? active,
    String? phone,
    String? password,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      role: role ?? this.role,
      active: active ?? this.active,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'role': role.code,
        'active': active,
        'phone': phone,
        'password': password,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        name: json['name'] as String,
        username: json['username'] as String,
        role: UserRoleExt.fromCode(json['role'] as String?),
        active: json['active'] as bool? ?? true,
        phone: json['phone'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );
}
