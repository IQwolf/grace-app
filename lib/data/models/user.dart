class User {
  final String id;
  final String phone;
  final String name;
  final String governorate;
  final String university;
  final DateTime birthDate;
  final Gender gender;
  final String? telegramUsername;

  const User({
    required this.id,
    required this.phone,
    required this.name,
    required this.governorate,
    required this.university,
    required this.birthDate,
    required this.gender,
    this.telegramUsername,
  });

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    Gender? gender,
    String? telegramUsername,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      governorate: governorate ?? this.governorate,
      university: university ?? this.university,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      telegramUsername: telegramUsername ?? this.telegramUsername,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'governorate': governorate,
      'university': university,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender.name,
      if (telegramUsername != null) 'telegramUsername': telegramUsername,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      governorate: json['governorate'],
      university: json['university'],
      birthDate: DateTime.parse(json['birthDate']),
      gender: Gender.values.byName(json['gender']),
      telegramUsername: json['telegramUsername'] == null ? null : json['telegramUsername'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum Gender { male, female }