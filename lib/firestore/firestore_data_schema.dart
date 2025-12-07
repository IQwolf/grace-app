import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';

/// Firestore data schema definitions for EduPulse app
/// This file defines the structure of documents in each collection

class FirestoreCollections {
  static const String users = 'users';
  static const String majors = 'majors';
  static const String instructors = 'instructors';
  static const String courses = 'courses';
  static const String lectures = 'lectures';
  static const String enrollments = 'enrollments';
  static const String userProgress = 'user_progress';
}

/// User document schema - stored in 'users' collection
/// Document ID: Firebase Auth UID
class UserDocument {
  static const String phone = 'phone';
  static const String name = 'name';
  static const String governorate = 'governorate';
  static const String university = 'university';
  static const String birthDate = 'birthDate';
  static const String gender = 'gender';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> fromModel(User user) {
    return {
      phone: user.phone,
      name: user.name,
      governorate: user.governorate,
      university: user.university,
      birthDate: user.birthDate.toIso8601String(),
      gender: user.gender.name,
      createdAt: "TIMESTAMP",
      updatedAt: "TIMESTAMP",
    };
  }

  static User toModel(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      phone: data[phone] ?? '',
      name: data[name] ?? '',
      governorate: data[governorate] ?? '',
      university: data[university] ?? '',
      birthDate: DateTime.parse(data[birthDate]),
      gender: Gender.values.byName(data[gender]),
    );
  }
}

/// Major document schema - stored in 'majors' collection
/// Document ID: Auto-generated
class MajorDocument {
  static const String name = 'name';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> fromModel(Major major) {
    return {
      name: major.name,
      createdAt: "TIMESTAMP",
      updatedAt: "TIMESTAMP",
    };
  }

  static Major toModel(String id, Map<String, dynamic> data) {
    return Major(
      id: id,
      name: data[name] ?? '',
    );
  }
}

/// Instructor document schema - stored in 'instructors' collection
/// Document ID: Auto-generated
class InstructorDocument {
  static const String name = 'name';
  static const String avatarUrl = 'avatarUrl';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> fromModel(Instructor instructor) {
    return {
      name: instructor.name,
      avatarUrl: instructor.avatarUrl,
      createdAt: "TIMESTAMP",
      updatedAt: "TIMESTAMP",
    };
  }

  static Instructor toModel(String id, Map<String, dynamic> data) {
    return Instructor(
      id: id,
      name: data[name] ?? '',
      avatarUrl: data[avatarUrl] ?? '',
    );
  }
}

/// Course document schema - stored in 'courses' collection
/// Document ID: Auto-generated
class CourseDocument {
  static const String title = 'title';
  static const String instructorId = 'instructorId';
  static const String majorId = 'majorId';
  static const String level = 'level';
  static const String track = 'track';
  static const String coverUrl = 'coverUrl';
  static const String lecturesCount = 'lecturesCount';
  static const String description = 'description';
  static const String pendingActivation = 'pendingActivation';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> fromModel(Course course) {
    return {
      title: course.title,
      instructorId: course.instructorId,
      majorId: course.majorId,
      level: course.level,
      track: course.track.name,
      coverUrl: course.coverUrl,
      lecturesCount: course.lecturesCount,
      description: course.description,
      pendingActivation: course.pendingActivation,
      createdAt: "TIMESTAMP",
      updatedAt: "TIMESTAMP",
    };
  }

  static Course toModel(String id, Map<String, dynamic> data, {bool isSubscribed = false}) {
    return Course(
      id: id,
      title: data[title] ?? '',
      instructorId: data[instructorId] ?? '',
      majorId: data[majorId] ?? '',
      level: data[level] ?? '',
      track: CourseTrack.values.byName(data[track] ?? 'first'),
      coverUrl: data[coverUrl] ?? '',
      lecturesCount: data[lecturesCount] ?? 0,
      description: data[description] ?? '',
      pendingActivation: data[pendingActivation] ?? false,
      isSubscribed: isSubscribed,
    );
  }
}

/// Lecture document schema - stored in 'lectures' collection
/// Document ID: Auto-generated
class LectureDocument {
  static const String courseId = 'courseId';
  static const String title = 'title';
  static const String order = 'order';
  static const String isFree = 'isFree';
  static const String videoUrl = 'videoUrl';
  static const String duration = 'duration';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> fromModel(Lecture lecture) {
    return {
      courseId: lecture.courseId,
      title: lecture.title,
      order: lecture.order,
      isFree: lecture.isFree,
      videoUrl: lecture.videoUrl,
      duration: lecture.duration.inSeconds,
      createdAt: "TIMESTAMP",
      updatedAt: "TIMESTAMP",
    };
  }

  static Lecture toModel(String id, Map<String, dynamic> data) {
    return Lecture(
      id: id,
      courseId: data[courseId] ?? '',
      title: data[title] ?? '',
      order: data[order] ?? 0,
      isFree: data[isFree] ?? false,
      videoUrl: data[videoUrl] ?? '',
      duration: Duration(seconds: data[duration] ?? 0),
    );
  }
}

/// Enrollment document schema - stored in 'enrollments' collection
/// Document ID: Auto-generated
class EnrollmentDocument {
  static const String userId = 'userId';
  static const String courseId = 'courseId';
  static const String enrolledAt = 'enrolledAt';
  static const String status = 'status'; // active, expired, cancelled
  static const String expiresAt = 'expiresAt';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> create({
    required String userId,
    required String courseId,
    required DateTime expiresAt,
    String status = 'active',
  }) {
    return {
      EnrollmentDocument.userId: userId,
      EnrollmentDocument.courseId: courseId,
      EnrollmentDocument.enrolledAt: "TIMESTAMP",
      EnrollmentDocument.status: status,
      EnrollmentDocument.expiresAt: expiresAt.toIso8601String(),
      EnrollmentDocument.createdAt: "TIMESTAMP",
      EnrollmentDocument.updatedAt: "TIMESTAMP",
    };
  }
}

/// User progress document schema - stored in 'user_progress' collection
/// Document ID: Auto-generated
class UserProgressDocument {
  static const String userId = 'userId';
  static const String lectureId = 'lectureId';
  static const String courseId = 'courseId';
  static const String watchedAt = 'watchedAt';
  static const String watchedDuration = 'watchedDuration'; // in seconds
  static const String totalDuration = 'totalDuration'; // in seconds
  static const String completed = 'completed';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static Map<String, dynamic> create({
    required String userId,
    required String lectureId,
    required String courseId,
    required int watchedDuration,
    required int totalDuration,
    bool completed = false,
  }) {
    return {
      UserProgressDocument.userId: userId,
      UserProgressDocument.lectureId: lectureId,
      UserProgressDocument.courseId: courseId,
      UserProgressDocument.watchedAt: "TIMESTAMP",
      UserProgressDocument.watchedDuration: watchedDuration,
      UserProgressDocument.totalDuration: totalDuration,
      UserProgressDocument.completed: completed,
      UserProgressDocument.createdAt: "TIMESTAMP",
      UserProgressDocument.updatedAt: "TIMESTAMP",
    };
  }
}