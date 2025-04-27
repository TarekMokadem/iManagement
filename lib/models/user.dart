class AppUser {
  final String id;
  final String name;
  final String code;
  final bool isAdmin;

  AppUser({
    required this.id,
    required this.name,
    required this.code,
    required this.isAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'isAdmin': isAdmin,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
      isAdmin: map['isAdmin'] as bool,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? code,
    bool? isAdmin,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
} 