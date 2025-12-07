class Instructor {
  final String id;
  final String name;
  final String avatarUrl;

  const Instructor({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  Instructor copyWith({
    String? id,
    String? name,
    String? avatarUrl,
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Instructor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}