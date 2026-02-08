import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime? birthDate;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.birthDate,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'birth_date': birthDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? avatarUrl,
    DateTime? birthDate,
    bool clearAvatarUrl = false,
    bool clearBirthDate = false,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      createdAt: createdAt,
    );
  }

  /// Calculate age from birth date
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [id, email, name, avatarUrl, birthDate, createdAt];
}
