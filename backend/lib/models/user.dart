class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromRow(Map<String, dynamic> row) {
    final createdAt = row['created_at'];
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      name: row['name'] as String,
      avatarUrl: row['avatar_url'] as String?,
      createdAt: createdAt is DateTime ? createdAt : DateTime.parse(createdAt.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
