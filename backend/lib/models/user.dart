import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt];

  factory User.fromJson(Map<String, dynamic> row) {
    return User(
      id: safeString(row, 'id'),
      email: safeString(row, 'email'),
      name: safeString(row, 'name'),
      avatarUrl: safeStringNullable(row, 'avatar_url'),
      createdAt: requireDateTime(row, 'created_at'),
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
