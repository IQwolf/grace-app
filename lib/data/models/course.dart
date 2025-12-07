class Course {
  final String id;
  final String title;
  final String instructorId;
  final String majorId;
  final String level;
  final CourseTrack track;
  final String coverUrl;
  final int lecturesCount;
  final String description;
  final bool pendingActivation;
  final bool isSubscribed;

  const Course({
    required this.id,
    required this.title,
    required this.instructorId,
    required this.majorId,
    required this.level,
    required this.track,
    required this.coverUrl,
    required this.lecturesCount,
    this.description = '',
    this.pendingActivation = false,
    this.isSubscribed = false,
  });

  Course copyWith({
    String? id,
    String? title,
    String? instructorId,
    String? majorId,
    String? level,
    CourseTrack? track,
    String? coverUrl,
    int? lecturesCount,
    String? description,
    bool? pendingActivation,
    bool? isSubscribed,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      instructorId: instructorId ?? this.instructorId,
      majorId: majorId ?? this.majorId,
      level: level ?? this.level,
      track: track ?? this.track,
      coverUrl: coverUrl ?? this.coverUrl,
      lecturesCount: lecturesCount ?? this.lecturesCount,
      description: description ?? this.description,
      pendingActivation: pendingActivation ?? this.pendingActivation,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructorId': instructorId,
      'majorId': majorId,
      'level': level,
      'track': track.name,
      'coverUrl': coverUrl,
      'lecturesCount': lecturesCount,
      'description': description,
      'pendingActivation': pendingActivation,
      'isSubscribed': isSubscribed,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      instructorId: json['instructorId'],
      majorId: json['majorId'],
      level: json['level'],
      track: CourseTrack.values.byName(json['track']),
      coverUrl: json['coverUrl'],
      lecturesCount: json['lecturesCount'],
      description: json['description'] ?? '',
      pendingActivation: json['pendingActivation'] ?? false,
      isSubscribed: json['isSubscribed'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum CourseTrack { first, second }
