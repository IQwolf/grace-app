class Major {
  final String id;
  final String name;

  const Major({
    required this.id,
    required this.name,
  });

  Major copyWith({
    String? id,
    String? name,
  }) {
    return Major(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Major && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}