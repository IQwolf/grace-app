import 'package:grace_academy/core/mock_data.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/data/models/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/data/models/major_levels.dart';
import 'package:grace_academy/data/models/app_notification.dart';
import 'package:grace_academy/data/models/university.dart';

/// Abstract API client interface for all backend operations
abstract class ApiClient {
  /// Authentication operations (Telegram Gateway via Cloud Functions)
  /// Returns requestId to be used with verifyOtp.
  Future<Result<String>> startOtp(String phone);

  /// Verifies OTP and returns existing user or 'new_user' failure to indicate profile is required.
  Future<Result<OtpVerificationResult>> verifyOtp(String phone, String otp, String requestId);

  Future<Result<bool>> hasAccount(String phone);
  Future<Result<User>> createProfile({
    required String phone,
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required Gender gender,
  });

  Future<Result<User>> getCurrentUser();
  Future<Result<User>> updateProfile({
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    Gender? gender,
    String? telegramUsername,
  });

  Future<Result<String?>> getTelegramUsername({required String phoneNumber});
  Future<Result<void>> updateTelegramUsername({
    required String phoneNumber,
    required String telegramUsername,
  });

  /// Account Deletion
  /// Step 1: Send OTP for account deletion. Returns requestId.
  Future<Result<String>> sendDeleteAccountOtp(String phone);
  
  /// Step 2: Verify OTP for account deletion. Returns verificationToken.
  Future<Result<String>> verifyDeleteAccountOtp(String phone, String otp, String requestId);

  /// Step 3: Confirm account deletion using verificationToken.
  Future<Result<void>> confirmDeleteAccount(String phone, String verificationToken);

  /// Notifications
  Future<Result<void>> saveFcmToken({required String studentId, required String phoneNumber, required String fcmToken});
  Future<Result<List<AppNotification>>> getNotifications({required String studentId});
  Future<Result<void>> markNotificationAsRead(String notificationId);

  /// Catalog operations
  Future<Result<List<Major>>> getMajors();
  Future<Result<List<String>>> getLevels();
  Future<Result<List<University>>> getUniversities({String? type});
  /// New: get majors with their available levels (dynamic)
  Future<Result<List<MajorLevels>>> getMajorsWithLevels();
  Future<Result<List<Course>>> getCourses({
    required String majorId,
    required String level,
    required CourseTrack track,
  });
  Future<Result<List<Lecture>>> getLectures(String courseId);
  Future<Result<Course>> getCourse(String courseId);
  Future<Result<Instructor>> getInstructor(String instructorId);

  /// Library operations
  Future<Result<List<Course>>> getLibraryCourses();
  Future<Result<void>> requestActivation(String courseId);

  /// Enrollment operations
  Future<Result<bool>> isUserEnrolledInCourse(String userId, String courseId);
  Future<Result<List<Course>>> getUserActiveCourses(String userId);

  /// Search operations
  Future<Result<List<Course>>> searchCourses(String query);

  /// Hero slider
  Future<Result<List<String>>> getHeroImages();
}

/// Mock implementation of ApiClient for UI-only development
class MockApiClient implements ApiClient {
  // Simulate network delays
  static const _networkDelay = Duration(milliseconds: 800);
  static const _otpValidity = Duration(minutes: 5);
  
  // In-memory state for mock data
  final Map<String, User> _users = {};
  final Map<String, DateTime> _otpIssuedAt = {};
  final Map<String, String> _otps = {};
  final Set<String> _activationRequests = {};
  final Set<String> _subscribedCourses = {};
  int _userCounter = 0;
  int _requestCounter = 0;
  String? _currentPhone;

  bool _isValidIraqiPhone(String phone) {
    return RegExp(r'^(\+964)?7[3789]\d{8}$').hasMatch(phone);
  }

  @override
  Future<Result<String>> startOtp(String phone) async {
    await Future.delayed(_networkDelay);
    
    try {
      // Mock validation - accept any valid Iraqi phone number
      if (!_isValidIraqiPhone(phone)) {
        return const Failure('رقم الهاتف غير صحيح');
      }
      
      // Simulate sending OTP via Telegram: store issue time and code
      _otpIssuedAt[phone] = DateTime.now();
      _otps[phone] = MockData.validOTP; // 123456 for demo
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}_${_requestCounter++}';
      return Success(requestId);
    } catch (e) {
      return Failure('خطأ في الشبكة: $e');
    }
  }

  // ---- Notifications (Mock) ----
  @override
  Future<Result<void>> saveFcmToken({required String studentId, required String phoneNumber, required String fcmToken}) async {
    await Future.delayed(_networkDelay);
    return const Success(null);
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications({required String studentId}) async {
    await Future.delayed(_networkDelay);
    // Simple mock history
    final now = DateTime.now();
    final list = [
      AppNotification(
        id: 'n1',
        studentId: studentId,
        title: 'تم تفعيل حسابك',
        body: 'مبروك! تم تفعيل حسابك ويمكنك البدء الآن',
        type: 'activation',
        status: 'sent',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'n2',
        studentId: studentId,
        title: 'تم تسجيلك في كورس جديد',
        body: 'اضغط لفتح تفاصيل الكورس',
        type: 'enrollment',
        status: 'sent',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];
    return Success(list);
  }

  @override
  Future<Result<void>> markNotificationAsRead(String notificationId) async {
    await Future.delayed(_networkDelay);
    return const Success(null);
  }

  @override
  Future<Result<OtpVerificationResult>> verifyOtp(String phone, String otp, String requestId) async {
    await Future.delayed(_networkDelay);
    
    try {
      // Check OTP expiry
      final issuedAt = _otpIssuedAt[phone];
      if (issuedAt == null || DateTime.now().difference(issuedAt) > _otpValidity) {
        return const Failure('انتهت صلاحية الرمز، يرجى طلب رمز جديد');
      }
      
      // Mock OTP validation
      if (otp != (_otps[phone] ?? MockData.validOTP)) {
        return const Failure('رمز التحقق خطأ');
      }
      
      // Check if user exists
      final existingUser = _users[phone];
      if (existingUser != null) {
        _currentPhone = phone;
        return Success(
          OtpVerificationResult(
            user: existingUser,
            token: 'dev_token_mock_${existingUser.id}',
            tokenType: 'dev_token',
          ),
        );
      }
      
      // Return null to indicate new user needs profile creation
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_backend_token', 'dev_token_mock_pending');
      await prefs.setString('auth_backend_token_type', 'dev_token');
      return const Failure('new_user');
    } catch (e) {
      return Failure('خطأ في الشبكة: $e');
    }
  }

  @override
  Future<Result<bool>> hasAccount(String phone) async {
    await Future.delayed(_networkDelay);
    try {
      // Validate phone
      if (!_isValidIraqiPhone(phone)) {
        return const Failure('رقم الهاتف غير صحيح');
      }
      return Success(_users.containsKey(phone));
    } catch (e) {
      return Failure('خطأ في الشبكة: $e');
    }
  }

  @override
  Future<Result<User>> createProfile({
    required String phone,
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required Gender gender,
  }) async {
    await Future.delayed(_networkDelay);
    
    try {
      final user = User(
        id: 'user_${++_userCounter}',
        phone: phone,
        name: name,
        governorate: governorate,
        university: university,
        birthDate: birthDate,
        gender: gender,
        telegramUsername: null,
      );
      
      _users[phone] = user;
      _currentPhone = phone;
      return Success(user);
    } catch (e) {
      return Failure('خطأ في إنشاء الحساب: $e');
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    await Future.delayed(_networkDelay);
    final phone = _currentPhone;
    if (phone == null) {
      return const Failure('غير مسجل الدخول');
    }
    final user = _users[phone];
    if (user == null) {
      return const Failure('الملف الشخصي غير موجود');
    }
    return Success(user);
  }

  @override
  Future<Result<User>> updateProfile({
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    Gender? gender,
    String? telegramUsername,
  }) async {
    await Future.delayed(_networkDelay);

    final phone = _currentPhone;
    if (phone == null) {
      return const Failure('غير مسجل الدخول');
    }

    final existing = _users[phone];
    if (existing == null) {
      return const Failure('الملف الشخصي غير موجود');
    }

    var updated = existing.copyWith(
      name: name ?? existing.name,
      governorate: governorate ?? existing.governorate,
      university: university ?? existing.university,
      birthDate: birthDate ?? existing.birthDate,
      gender: gender ?? existing.gender,
      telegramUsername: telegramUsername ?? existing.telegramUsername,
    );

    _users[phone] = updated;
    return Success(updated);
  }

  @override
  Future<Result<String?>> getTelegramUsername({required String phoneNumber}) async {
    await Future.delayed(_networkDelay);
    final user = _users[phoneNumber];
    if (user == null) {
      return const Failure('الملف الشخصي غير موجود');
    }
    final value = user.telegramUsername;
    return Success(value == null || value.trim().isEmpty ? null : value.trim());
  }

  @override
  Future<Result<void>> updateTelegramUsername({
    required String phoneNumber,
    required String telegramUsername,
  }) async {
    await Future.delayed(_networkDelay);
    final existing = _users[phoneNumber];
    if (existing == null) {
      return const Failure('الملف الشخصي غير موجود');
    }
    _users[phoneNumber] = existing.copyWith(telegramUsername: telegramUsername.trim());
    return const Success(null);
  }

  // ---- Account Deletion (Mock) ----
  
  @override
  Future<Result<String>> sendDeleteAccountOtp(String phone) async {
    await Future.delayed(_networkDelay);
    _otpIssuedAt[phone] = DateTime.now();
    _otps[phone] = '123456'; 
    return Success('mock_delete_request_id_${DateTime.now().millisecondsSinceEpoch}');
  }

  @override
  Future<Result<String>> verifyDeleteAccountOtp(String phone, String otp, String requestId) async {
    await Future.delayed(_networkDelay);
    if (otp == '123456') {
      return Success('mock_delete_token_${DateTime.now().millisecondsSinceEpoch}');
    }
    return const Failure('رمز التحقق غير صحيح');
  }

  @override
  Future<Result<void>> confirmDeleteAccount(String phone, String verificationToken) async {
    await Future.delayed(_networkDelay);
    _users.remove(phone);
    if (_currentPhone == phone) {
      _currentPhone = null;
    }
    return const Success(null);
  }

  @override
  Future<Result<List<Major>>> getMajors() async {
    await Future.delayed(_networkDelay);
    
    try {
      return const Success(MockData.majors);
    } catch (e) {
      return Failure('خطأ في تحميل التخصصات: $e');
    }
  }

  @override
  Future<Result<List<String>>> getLevels() async {
    await Future.delayed(_networkDelay);
    
    try {
      return const Success(MockData.levels);
    } catch (e) {
      return Failure('خطأ في تحميل المراحل: $e');
    }
  }

  @override
  Future<Result<List<University>>> getUniversities({String? type}) async {
    await Future.delayed(_networkDelay);

    try {
      final now = DateTime.now();
      final baseList = MockData.universities.asMap().entries.map((entry) {
        final name = entry.value;
        final inferredType = entry.key.isEven ? 'حكومي' : 'أهلي';
        return University(
          id: 'mock_${entry.key + 1}',
          name: name,
          type: inferredType,
          createdAt: now.subtract(Duration(days: entry.key + 1)),
          updatedAt: now.subtract(Duration(days: entry.key + 1)),
        );
      }).toList();

      final filtered = (type == null || type.trim().isEmpty)
          ? baseList
          : baseList.where((u) => u.type == type).toList();

      return Success(filtered);
    } catch (e) {
      return Failure('خطأ في تحميل الجامعات: $e');
    }
  }

  @override
  Future<Result<List<Course>>> getCourses({
    required String majorId,
    required String level,
    required CourseTrack track,
  }) async {
    await Future.delayed(_networkDelay);
    
    try {
      final filteredCourses = MockData.courses
          .where((course) => 
              course.majorId == majorId && 
              course.level == level && 
              course.track == track)
          .map((course) => course.copyWith(
              isSubscribed: _subscribedCourses.contains(course.id),
              pendingActivation: _activationRequests.contains(course.id),
          ))
          .toList();
          
      return Success(filteredCourses);
    } catch (e) {
      return Failure('خطأ في تحميل الكورسات: $e');
    }
  }

  @override
  Future<Result<List<Lecture>>> getLectures(String courseId) async {
    await Future.delayed(_networkDelay);
    
    try {
      final lectures = MockData.lectures
          .where((lecture) => lecture.courseId == courseId)
          .toList();
          
      return Success(lectures);
    } catch (e) {
      return Failure('خطأ في تحميل المحاضرات: $e');
    }
  }

  @override
  Future<Result<Course>> getCourse(String courseId) async {
    await Future.delayed(_networkDelay);
    
    try {
      final course = MockData.courses
          .where((c) => c.id == courseId)
          .firstOrNull;
          
      if (course == null) {
        return const Failure('الكورس غير موجود');
      }
      
      final updatedCourse = course.copyWith(
        isSubscribed: _subscribedCourses.contains(course.id),
        pendingActivation: _activationRequests.contains(course.id),
      );
      
      return Success(updatedCourse);
    } catch (e) {
      return Failure('خطأ في تحميل الكورس: $e');
    }
  }

  @override
  Future<Result<Instructor>> getInstructor(String instructorId) async {
    await Future.delayed(_networkDelay);
    
    try {
      final instructor = MockData.instructors
          .where((i) => i.id == instructorId)
          .firstOrNull;
          
      if (instructor == null) {
        return const Failure('المدرس غير موجود');
      }
      
      return Success(instructor);
    } catch (e) {
      return Failure('خطأ في تحميل بيانات المدرس: $e');
    }
  }

  @override
  Future<Result<List<Course>>> getLibraryCourses() async {
    await Future.delayed(_networkDelay);
    
    try {
      final libraryCourses = MockData.courses
          .where((course) => 
              _subscribedCourses.contains(course.id) || 
              _activationRequests.contains(course.id))
          .map((course) => course.copyWith(
              isSubscribed: _subscribedCourses.contains(course.id),
              pendingActivation: _activationRequests.contains(course.id),
          ))
          .toList();
          
      return Success(libraryCourses);
    } catch (e) {
      return Failure('خطأ في تحميل المكتبة: $e');
    }
  }

  @override
  Future<Result<void>> requestActivation(String courseId) async {
    await Future.delayed(_networkDelay);
    
    try {
      _activationRequests.add(courseId);
      return const Success(null);
    } catch (e) {
      return Failure('خطأ في إرسال طلب التفعيل: $e');
    }
  }

  // ---- Enrollment (Mock) ----
  @override
  Future<Result<bool>> isUserEnrolledInCourse(String userId, String courseId) async {
    await Future.delayed(_networkDelay);
    try {
      return Success(_subscribedCourses.contains(courseId));
    } catch (e) {
      return Failure('خطأ في التحقق من حالة الاشتراك: $e');
    }
  }

  @override
  Future<Result<List<Course>>> getUserActiveCourses(String userId) async {
    await Future.delayed(_networkDelay);
    try {
      final courses = MockData.courses
          .where((c) => _subscribedCourses.contains(c.id))
          .map((c) => c.copyWith(isSubscribed: true))
          .toList();
      return Success(courses);
    } catch (e) {
      return Failure('خطأ في جلب الكورسات المفعلة: $e');
    }
  }

  @override
  Future<Result<List<Course>>> searchCourses(String query) async {
    await Future.delayed(_networkDelay);
    
    try {
      if (query.trim().isEmpty) {
        return const Success([]);
      }
      
      final results = MockData.courses
          .where((course) => 
              course.title.toLowerCase().contains(query.toLowerCase()))
          .map((course) => course.copyWith(
              isSubscribed: _subscribedCourses.contains(course.id),
              pendingActivation: _activationRequests.contains(course.id),
          ))
          .toList();
          
      return Success(results);
    } catch (e) {
      return Failure('خطأ في البحث: $e');
    }
  }

  @override
  Future<Result<List<MajorLevels>>> getMajorsWithLevels() async {
    await Future.delayed(_networkDelay);
    try {
      // Build dynamic mapping from mock courses
      final Map<String, Set<String>> levelsByMajor = {};
      for (final c in MockData.courses) {
        levelsByMajor.putIfAbsent(c.majorId, () => <String>{}).add(c.level);
      }
      // Resolve major names from MockData.majors, fallback to id
      final majorsById = {for (final m in MockData.majors) m.id: m.name};
      final items = levelsByMajor.entries.map((e) {
        final id = e.key;
        final name = majorsById[id] ?? id;
        final levels = e.value.toList()..sort();
        return MajorLevels(id: id, name: name, levels: levels);
      }).toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return Success(items);
    } catch (e) {
      return Failure('خطأ في تحميل التخصصات والمراحل: $e');
    }
  }

  @override
  Future<Result<List<String>>> getHeroImages() async {
    await Future.delayed(_networkDelay);
    
    try {
      return const Success(MockData.heroImages);
    } catch (e) {
      return Failure('خطأ في تحميل الصور: $e');
    }
  }
}

extension on List<Course> {
  Course? get firstOrNull => isEmpty ? null : first;
}

extension on List<Instructor> {
  Instructor? get firstOrNull => isEmpty ? null : first;
}
