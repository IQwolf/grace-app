import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_academy/data/repositories/firestore_repository.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';
import 'package:grace_academy/providers/auth_provider.dart';
import 'package:grace_academy/core/result.dart';

// Provider for course data
final coursesProvider = FutureProvider.family<List<Course>, CourseFilter>((ref, filter) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getCourses(
    majorId: filter.majorId,
    track: filter.track,
    level: filter.level,
    limit: filter.limit,
  );

  return result.when(
    success: (courses) => courses,
    failure: (_) => [],
  );
});

// Provider for single course
final courseProvider = FutureProvider.family<Course?, String>((ref, courseId) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getCourse(courseId);

  return result.when(
    success: (course) => course,
    failure: (_) => null,
  );
});

// Provider for course lectures
final courseLecturesProvider = FutureProvider.family<List<Lecture>, String>((ref, courseId) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getCourseLectures(courseId);

  return result.when(
    success: (lectures) => lectures,
    failure: (_) => [],
  );
});

// Provider for single lecture
final lectureProvider = FutureProvider.family<Lecture?, String>((ref, lectureId) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getLecture(lectureId);

  return result.when(
    success: (lecture) => lecture,
    failure: (_) => null,
  );
});

// Provider for majors
final majorsProvider = FutureProvider<List<Major>>((ref) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getMajors();

  return result.when(
    success: (majors) => majors,
    failure: (_) => [],
  );
});

// Provider for instructors
final instructorsProvider = FutureProvider<List<Instructor>>((ref) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getInstructors();

  return result.when(
    success: (instructors) => instructors,
    failure: (_) => [],
  );
});

// Provider for single instructor
final instructorProvider = FutureProvider.family<Instructor?, String>((ref, instructorId) async {
  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getInstructor(instructorId);

  return result.when(
    success: (instructor) => instructor,
    failure: (_) => null,
  );
});

// Provider for enrolled courses
final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getUserEnrolledCourses(currentUser.uid);

  return result.when(
    success: (courses) => courses,
    failure: (_) => [],
  );
});

// Provider for search results
final searchResultsProvider = FutureProvider.family<List<Course>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.searchCourses(query, limit: 20);

  return result.when(
    success: (courses) => courses,
    failure: (_) => [],
  );
});

// Provider for user progress in a course
final courseProgressProvider = FutureProvider.family<Map<String, double>, String>((ref, courseId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return {};

  final firestoreRepo = ref.watch(firestoreRepositoryProvider);
  final result = await firestoreRepo.getUserCourseProgress(currentUser.uid, courseId);

  return result.when(
    success: (progress) => progress,
    failure: (_) => {},
  );
});

// Notifier for course operations
class CourseController extends Notifier<AsyncValue<void>> {
  late final FirestoreRepository _firestoreRepository;

  @override
  AsyncValue<void> build() {
    _firestoreRepository = ref.read(firestoreRepositoryProvider);
    return const AsyncValue.data(null);
  }

  // Enroll user in course
  Future<Result<void>> enrollInCourse({
    required String userId,
    required String courseId,
    DateTime? expiresAt,
  }) async {
    state = const AsyncValue.loading();

    final result = await _firestoreRepository.enrollUserInCourse(
      userId: userId,
      courseId: courseId,
      expiresAt: expiresAt,
    );

    if (result.isSuccess) {
      state = const AsyncValue.data(null);
    } else {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }

    return result;
  }

  // Check if user is enrolled in course
  Future<bool> isEnrolledInCourse({
    required String userId,
    required String courseId,
  }) async {
    final result = await _firestoreRepository.isUserEnrolledInCourse(
      userId: userId,
      courseId: courseId,
    );

    return result.when(
      success: (isEnrolled) => isEnrolled,
      failure: (_) => false,
    );
  }

  // Update user progress
  Future<Result<void>> updateProgress({
    required String userId,
    required String lectureId,
    required String courseId,
    required int watchedDuration,
    required int totalDuration,
    bool completed = false,
  }) async {
    final result = await _firestoreRepository.updateUserProgress(
      userId: userId,
      lectureId: lectureId,
      courseId: courseId,
      watchedDuration: watchedDuration,
      totalDuration: totalDuration,
      completed: completed,
    );

    if (result.isFailure) {
      state = AsyncValue.error(result.error ?? 'Unknown error', StackTrace.current);
    }

    return result;
  }
}

// Provider for Course Controller
final courseControllerProvider = NotifierProvider<CourseController, AsyncValue<void>>(CourseController.new);

// Filter class for courses
class CourseFilter {
  final String? majorId;
  final CourseTrack? track;
  final String? level;
  final int limit;

  const CourseFilter({
    this.majorId,
    this.track,
    this.level,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CourseFilter &&
              runtimeType == other.runtimeType &&
              majorId == other.majorId &&
              track == other.track &&
              level == other.level &&
              limit == other.limit;

  @override
  int get hashCode => majorId.hashCode ^ track.hashCode ^ level.hashCode ^ limit.hashCode;
}