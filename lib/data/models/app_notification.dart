import 'package:flutter/foundation.dart';

/// App notification model mapped from backend API
/// Supports types: activation | enrollment | manual
class AppNotification {
  final String id;
  final String studentId;
  final String title;
  final String body;
  final String type; // activation | enrollment | manual
  final String status; // sent | failed
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.studentId,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
  });

  AppNotification copyWith({
    String? id,
    String? studentId,
    String? title,
    String? body,
    String? type,
    String? status,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
  }) => AppNotification(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    title: title ?? this.title,
    body: body ?? this.body,
    type: type ?? this.type,
    status: status ?? this.status,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    readAt: readAt ?? this.readAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    final readAt = parseDate(json['readAt']);
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      title: (json['title'] ?? json['notification']?['title'] ?? '').toString(),
      body: (json['body'] ?? json['notification']?['body'] ?? '').toString(),
      type: (json['type'] ?? json['data']?['type'] ?? 'manual').toString(),
      status: (json['status'] ?? 'sent').toString(),
      isRead: readAt != null || json['isRead'] == true || json['is_read'] == true,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']),
      readAt: readAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'title': title,
    'body': body,
    'type': type,
    'status': status,
    'isRead': isRead,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    if (readAt != null) 'readAt': readAt!.toUtc().toIso8601String(),
  };
}
