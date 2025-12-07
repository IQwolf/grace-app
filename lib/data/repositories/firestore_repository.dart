import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/models/user.dart' as app_user;
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';
import 'package:grace_academy/firestore/firestore_data_schema.dart';

class FirestoreRepository {
  static final FirestoreRepository _instance = FirestoreRepository._internal();
  factory FirestoreRepository() => _instance;
  FirestoreRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<Result<void>> createUser({
    required String userId,
    required app_user.User user,
  }) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .set(UserDocument.fromModel(user));
      return Success(null);
    } catch (e) {
      return Failure('Failed to create user: $e');
    }
  }

  Future<Result<app_user.User?>> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return Success(UserDocument.toModel(doc.id, doc.data()!));
      } else {
        return Success(null);
      }
    } catch (e) {
      return Failure('Failed to get user: $e');
    }
  }

  Future<Result<void>> updateUser({
    required String userId,
    required app_user.User user,
  }) async {
    try {
      final data = UserDocument.fromModel(user);
      data[UserDocument.updatedAt] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .update(data);
      return Success(null);
    } catch (e) {
      return Failure('Failed to update user: $e');
    }
  }

  // Major operations
  Future<Result<List<Major>>> getMajors() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.majors)
          .get();
      
      final majors = snapshot.docs
          .map((doc) => MajorDocument.toModel(doc.id, doc.data()))
          .toList();
      
      return Success(majors);
    } catch (e) {
      return Failure('Failed to get majors: $e');
    }
  }

  // Instructor operations
  Future<Result<List<Instructor>>> getInstructors() async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.instructors)
          .get();
      
      final instructors = snapshot.docs
          .map((doc) => InstructorDocument.toModel(doc.id, doc.data()))
          .toList();
      
      return Success(instructors);
    } catch (e) {
      return Failure('Failed to get instructors: $e');
    }
  }

  Future<Result<Instructor?>> getInstructor(String instructorId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.instructors)
          .doc(instructorId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return Success(InstructorDocument.toModel(doc.id, doc.data()!));
      } else {
        return Success(null);
      }
    } catch (e) {
      return Failure('Failed to get instructor: $e');
    }
  }

  // Course operations
  Future<Result<List<Course>>> getCourses({
    String? majorId,
    CourseTrack? track,
    String? level,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(FirestoreCollections.courses);
      
      if (majorId != null) {
        query = query.where(CourseDocument.majorId, isEqualTo: majorId);
      }
      
      if (track != null) {
        query = query.where(CourseDocument.track, isEqualTo: track.name);
      }
      
      if (level != null) {
        query = query.where(CourseDocument.level, isEqualTo: level);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      final courses = <Course>[];
      for (final doc in snapshot.docs) {
        // Check if user is enrolled in course
        final isSubscribed = await _isUserEnrolledInCourse(doc.id);
        final course = CourseDocument.toModel(doc.id, doc.data() as Map<String, dynamic>, 
            isSubscribed: isSubscribed);
        courses.add(course);
      }
      
      return Success(courses);
    } catch (e) {
      return Failure('Failed to get courses: $e');
    }
  }

  Future<Result<Course?>> getCourse(String courseId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.courses)
          .doc(courseId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final isSubscribed = await _isUserEnrolledInCourse(courseId);
        final course = CourseDocument.toModel(doc.id, doc.data()!, 
            isSubscribed: isSubscribed);
        return Success(course);
      } else {
        return Success(null);
      }
    } catch (e) {
      return Failure('Failed to get course: $e');
    }
  }

  Future<Result<List<Course>>> getUserEnrolledCourses(String userId) async {
    try {
      final enrollmentSnapshot = await _firestore
          .collection(FirestoreCollections.enrollments)
          .where(EnrollmentDocument.userId, isEqualTo: userId)
          .where(EnrollmentDocument.status, isEqualTo: 'active')
          .get();
      
      final courseIds = enrollmentSnapshot.docs
          .map((doc) => doc.data()[EnrollmentDocument.courseId] as String)
          .toList();
      
      if (courseIds.isEmpty) {
        return Success([]);
      }
      
      final courses = <Course>[];
      for (final courseId in courseIds) {
        final courseResult = await getCourse(courseId);
        if (courseResult.isSuccess && courseResult.data != null) {
          courses.add(courseResult.data!);
        }
      }
      
      return Success(courses);
    } catch (e) {
      return Failure('Failed to get enrolled courses: $e');
    }
  }

  // Lecture operations
  Future<Result<List<Lecture>>> getCourseLectures(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.lectures)
          .where(LectureDocument.courseId, isEqualTo: courseId)
          .orderBy(LectureDocument.order)
          .get();
      
      final lectures = snapshot.docs
          .map((doc) => LectureDocument.toModel(doc.id, doc.data()))
          .toList();
      
      return Success(lectures);
    } catch (e) {
      return Failure('Failed to get course lectures: $e');
    }
  }

  Future<Result<Lecture?>> getLecture(String lectureId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.lectures)
          .doc(lectureId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return Success(LectureDocument.toModel(doc.id, doc.data()!));
      } else {
        return Success(null);
      }
    } catch (e) {
      return Failure('Failed to get lecture: $e');
    }
  }

  // Enrollment operations
  Future<Result<void>> enrollUserInCourse({
    required String userId,
    required String courseId,
    DateTime? expiresAt,
  }) async {
    try {
      final enrollmentData = EnrollmentDocument.create(
        userId: userId,
        courseId: courseId,
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 365)),
      );
      
      await _firestore
          .collection(FirestoreCollections.enrollments)
          .add(enrollmentData);
      
      return Success(null);
    } catch (e) {
      return Failure('Failed to enroll user in course: $e');
    }
  }

  Future<bool> _isUserEnrolledInCourse(String courseId) async {
    try {
      // This would typically use the current user's ID
      // For now, returning false as a placeholder
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Result<bool>> isUserEnrolledInCourse({
    required String userId,
    required String courseId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.enrollments)
          .where(EnrollmentDocument.userId, isEqualTo: userId)
          .where(EnrollmentDocument.courseId, isEqualTo: courseId)
          .where(EnrollmentDocument.status, isEqualTo: 'active')
          .limit(1)
          .get();
      
      return Success(snapshot.docs.isNotEmpty);
    } catch (e) {
      return Failure('Failed to check enrollment: $e');
    }
  }

  // User progress operations
  Future<Result<void>> updateUserProgress({
    required String userId,
    required String lectureId,
    required String courseId,
    required int watchedDuration,
    required int totalDuration,
    bool completed = false,
  }) async {
    try {
      // Check if progress already exists
      final existingProgressQuery = await _firestore
          .collection(FirestoreCollections.userProgress)
          .where(UserProgressDocument.userId, isEqualTo: userId)
          .where(UserProgressDocument.lectureId, isEqualTo: lectureId)
          .limit(1)
          .get();
      
      final progressData = UserProgressDocument.create(
        userId: userId,
        lectureId: lectureId,
        courseId: courseId,
        watchedDuration: watchedDuration,
        totalDuration: totalDuration,
        completed: completed,
      );
      
      if (existingProgressQuery.docs.isEmpty) {
        // Create new progress
        await _firestore
            .collection(FirestoreCollections.userProgress)
            .add(progressData);
      } else {
        // Update existing progress
        progressData[UserProgressDocument.createdAt] = existingProgressQuery.docs.first.data()[UserProgressDocument.createdAt];
        progressData[UserProgressDocument.updatedAt] = FieldValue.serverTimestamp();
        
        await _firestore
            .collection(FirestoreCollections.userProgress)
            .doc(existingProgressQuery.docs.first.id)
            .update(progressData);
      }
      
      return Success(null);
    } catch (e) {
      return Failure('Failed to update user progress: $e');
    }
  }

  Future<Result<Map<String, double>>> getUserCourseProgress(String userId, String courseId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestoreCollections.userProgress)
          .where(UserProgressDocument.userId, isEqualTo: userId)
          .where(UserProgressDocument.courseId, isEqualTo: courseId)
          .get();
      
      final progressMap = <String, double>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lectureId = data[UserProgressDocument.lectureId] as String;
        final watchedDuration = data[UserProgressDocument.watchedDuration] as int;
        final totalDuration = data[UserProgressDocument.totalDuration] as int;
        
        if (totalDuration > 0) {
          progressMap[lectureId] = (watchedDuration / totalDuration).clamp(0.0, 1.0);
        } else {
          progressMap[lectureId] = 0.0;
        }
      }
      
      return Success(progressMap);
    } catch (e) {
      return Failure('Failed to get user progress: $e');
    }
  }

  // Search operations
  Future<Result<List<Course>>> searchCourses(String query, {int limit = 10}) async {
    try {
      // Simple text search - for more advanced search, consider using Algolia
      final snapshot = await _firestore
          .collection(FirestoreCollections.courses)
          .where(CourseDocument.title, isGreaterThanOrEqualTo: query)
          .where(CourseDocument.title, isLessThanOrEqualTo: '$query\uf8ff')
          .limit(limit)
          .get();
      
      final courses = <Course>[];
      for (final doc in snapshot.docs) {
        final isSubscribed = await _isUserEnrolledInCourse(doc.id);
        final course = CourseDocument.toModel(doc.id, doc.data(), 
            isSubscribed: isSubscribed);
        courses.add(course);
      }
      
      return Success(courses);
    } catch (e) {
      return Failure('Failed to search courses: $e');
    }
  }
}