class AppUser {
  final String id;
  final String name;
  final String code;
  final bool isAdmin;
  final String tenantId;

  AppUser({
    required this.id,
    required this.name,
    required this.code,
    required this.isAdmin,
    required this.tenantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'isAdmin': isAdmin,
      'tenantId': tenantId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      isAdmin: map['isAdmin'] as bool,
      tenantId: (map['tenantId'] as String?) ?? 'default',
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? code,
    bool? isAdmin,
    String? tenantId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isAdmin: isAdmin ?? this.isAdmin,
      tenantId: tenantId ?? this.tenantId,
    );
  }
} 