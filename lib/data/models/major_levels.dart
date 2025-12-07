class MajorLevels {
  final String id;
  final String name;
  final List<String> levels;

  const MajorLevels({
    required this.id,
    required this.name,
    required this.levels,
  });

  factory MajorLevels.fromJson(Map<String, dynamic> json) {
    final lv = (json['levels'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    return MajorLevels(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      levels: lv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'levels': levels,
    };
  }
}