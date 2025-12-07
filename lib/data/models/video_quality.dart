class VideoQuality {
  final String quality;
  final String url;
  final int width;
  final int height;
  final int size;

  const VideoQuality({
    required this.quality,
    required this.url,
    required this.width,
    required this.height,
    required this.size,
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      quality: json['quality'] ?? '',
      url: json['url'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'quality': quality,
    'url': url,
    'width': width,
    'height': height,
    'size': size,
  };

  String get sizeInMB => '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoQuality && runtimeType == other.runtimeType && quality == other.quality;

  @override
  int get hashCode => quality.hashCode;
}
