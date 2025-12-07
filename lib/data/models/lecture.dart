class Lecture {
  final String id;
  final String courseId;
  final String title;
  final int order;
  final bool isFree;
  final String videoUrl;
  final Duration duration;

  const Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
    required this.isFree,
    required this.videoUrl,
    required this.duration,
  });

  Lecture copyWith({
    String? id,
    String? courseId,
    String? title,
    int? order,
    bool? isFree,
    String? videoUrl,
    Duration? duration,
  }) {
    return Lecture(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      order: order ?? this.order,
      isFree: isFree ?? this.isFree,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
      'isFree': isFree,
      'videoUrl': videoUrl,
      'duration': duration.inSeconds,
    };
  }

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'],
      courseId: json['courseId'],
      title: json['title'],
      order: json['order'],
      isFree: json['isFree'],
      videoUrl: json['videoUrl'],
      duration: Duration(seconds: json['duration']),
    );
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lecture && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}