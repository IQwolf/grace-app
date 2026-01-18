import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
// Cloud Functions package is intentionally not imported to keep the app compiling
// without requiring Firebase setup in Dreamflow.
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/foundation.dart';

import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/course.dart' as domain;
import 'package:grace_academy/data/models/auth_session.dart';
import 'package:grace_academy/data/models/instructor.dart' as domain;
import 'package:grace_academy/data/models/lecture.dart' as domain;
import 'package:grace_academy/data/models/user.dart' as domain;
import 'package:grace_academy/data/models/major.dart' as domain;
import 'package:grace_academy/data/repositories/firebase_auth_repository.dart';
import 'package:grace_academy/data/repositories/firestore_repository.dart';
import 'package:grace_academy/data/models/major_levels.dart';
import 'package:grace_academy/data/models/app_notification.dart';
import 'package:grace_academy/data/models/university.dart';

class FirebaseApiClient implements ApiClient {
  final FirebaseAuthRepository _authRepo = FirebaseAuthRepository();
  final FirestoreRepository _firestoreRepo = FirestoreRepository();
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // Cloud Functions client removed to avoid dependency when Firebase is not connected.

  // Ensure Firebase is initialized once
  static Future<void>? _initFuture;
  Future<void> _ensureInitialized() {
    return _initFuture ??= Firebase.initializeApp();
  }

  // Helper: current uid
  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Result<String>> startOtp(String phone) async {
    try {
      await _ensureInitialized();
      // Cloud Functions is not available until Firebase is connected in Dreamflow.
      // Provide a graceful message instead of a compile-time dependency.
      return const Failure(
        'خدمة OTP غير متوفرة. من فضلك افتح لوحة Firebase في Dreamflow وأكمل الإعداد.'
      );
    } catch (e) {
      return Failure(_mapFunctionsError(e));
    }
  }

  @override
  Future<Result<OtpVerificationResult>> verifyOtp(String phone, String otp, String requestId) async {
    try {
      await _ensureInitialized();
      // Cloud Functions is not available until Firebase is connected in Dreamflow.
      return const Failure(
        'خدمة OTP غير متوفرة. من فضلك افتح لوحة Firebase في Dreamflow وأكمل الإعداد.'
      );
    } catch (e) {
      return Failure(_mapFunctionsError(e));
    }
  }

  @override
  Future<Result<bool>> hasAccount(String phone) async {
    try {
      await _ensureInitialized();
      final q = await _db
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      return Success(q.docs.isNotEmpty);
    } catch (e) {
      return Failure('تعذر التحقق من الحساب: $e');
    }
  }

  @override
  Future<Result<domain.User>> createProfile({
    required String phone,
    required String name,
    required String governorate,
    required String university,
    required DateTime birthDate,
    required domain.Gender gender,
  }) async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) {
        return const Failure('غير مسجل الدخول');
      }

      final userRef = _db.collection('users').doc(uid);
      await userRef.set({
        'id': uid,
        'phone': phone,
        'name': name,
        'governorate': governorate,
        'university': university,
        'birthDate': birthDate.toIso8601String(),
        'gender': gender.name,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final data = (await userRef.get()).data()!;
      return Success(_userFromMap(data));
    } catch (e) {
      return Failure('خطأ في إنشاء الحساب: $e');
    }
  }

  @override
  Future<Result<domain.User>> getCurrentUser() async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) {
        return const Failure('غير مسجل الدخول');
      }
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Failure('الملف الشخصي غير موجود');
      }
      return Success(_userFromMap(doc.data()!));
    } catch (e) {
      return Failure('خطأ في تحميل الحساب: $e');
    }
  }

  @override
  Future<Result<domain.User>> updateProfile({
    String? name,
    String? governorate,
    String? university,
    DateTime? birthDate,
    domain.Gender? gender,
    String? telegramUsername,
  }) async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) {
        return const Failure('غير مسجل الدخول');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (governorate != null) updates['governorate'] = governorate;
      if (university != null) updates['university'] = university;
      if (birthDate != null) updates['birthDate'] = birthDate.toIso8601String();
      if (gender != null) updates['gender'] = gender.name;
      if (telegramUsername != null) updates['telegramUsername'] = telegramUsername;
      if (updates.isEmpty) {
        return const Failure('لا توجد بيانات للتحديث');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      final ref = _db.collection('users').doc(uid);
      await ref.set(updates, SetOptions(merge: true));
      final data = (await ref.get()).data();
      if (data == null) {
        return const Failure('الملف الشخصي غير موجود');
      }
      return Success(_userFromMap(data));
    } catch (e) {
      return Failure('خطأ في تحديث الحساب: $e');
    }
  }

  @override
  Future<Result<String?>> getTelegramUsername({required String phoneNumber}) async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) {
        return const Failure('غير مسجل الدخول');
      }
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return const Failure('الملف الشخصي غير موجود');
      }
      final data = doc.data() ?? <String, dynamic>{};
      final raw = (data['telegramUsername'] ?? '').toString().trim();
      if (raw.isEmpty) {
        return const Success(null);
      }
      return Success(raw);
    } catch (e) {
      return Failure('خطأ في تحميل اسم المستخدم: $e');
    }
  }

  @override
  Future<Result<void>> updateTelegramUsername({
    required String phoneNumber,
    required String telegramUsername,
  }) async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) {
        return const Failure('غير مسجل الدخول');
      }
      final normalized = telegramUsername.trim();
      await _db.collection('users').doc(uid).set(
        {'telegramUsername': normalized},
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (e) {
      return Failure('خطأ في تحديث اسم المستخدم: $e');
    }
  }

  // ---------------- Account Deletion ----------------

  @override
  Future<Result<String>> sendDeleteAccountOtp(String phone) async {
    return const Failure('حذف الحساب غير مدعوم في هذا الإصدار');
  }

  @override
  Future<Result<String>> verifyDeleteAccountOtp(String phone, String otp, String requestId) async {
    return const Failure('حذف الحساب غير مدعوم في هذا الإصدار');
  }

  @override
  Future<Result<void>> confirmDeleteAccount(String phone, String verificationToken) async {
    return const Failure('حذف الحساب غير مدعوم في هذا الإصدار');
  }

  @override
  Future<Result<List<MajorLevels>>> getMajorsWithLevels() async {
    try {
      await _ensureInitialized();
      final q = await _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .limit(2000)
          .get();
      final Map<String, Set<String>> levelsByMajor = {};
      for (final d in q.docs) {
        final m = d.data();
        final mid = (m['majorId'] ?? '').toString();
        final lvl = (m['level'] ?? '').toString();
        if (mid.isEmpty || lvl.isEmpty) continue;
        levelsByMajor.putIfAbsent(mid, () => <String>{}).add(lvl);
      }
      final items = levelsByMajor.entries.map((e) {
        return MajorLevels(
          id: e.key,
          name: e.key, // If you maintain a majors collection with names, map here.
          levels: e.value.toList()..sort(),
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(items);
    } catch (e) {
      return Failure('خطأ في تحميل التخصصات والمراحل: $e');
    }
  }

  @override
  // ---- Notifications stubs ----
   @override
   Future<Result<void>> saveFcmToken({required String studentId, required String phoneNumber, required String fcmToken}) async {
     try {
       await _ensureInitialized();
       // Optionally store in Firestore under current user
       final uid = _uid;
       final docId = uid ?? studentId;
       await _db.collection('users').doc(docId).collection('fcmTokens').doc(fcmToken).set({
         'phoneNumber': phoneNumber,
         'createdAt': FieldValue.serverTimestamp(),
       }, SetOptions(merge: true));
       return const Success(null);
     } catch (e) {
       return Failure('فشل حفظ رمز الإشعارات: $e');
     }
   }

   @override
   Future<Result<List<AppNotification>>> getNotifications({required String studentId}) async {
     try {
       await _ensureInitialized();
       // If you maintain notifications in Firestore, query here.
       // For now, return empty to keep feature optional.
       return const Success(<AppNotification>[]);
     } catch (e) {
       return Failure('فشل تحميل الإشعارات: $e');
     }
   }

   @override
   Future<Result<void>> markNotificationAsRead(String notificationId) async {
     try {
       await _ensureInitialized();
       // For Firebase, you would update the notification document here
       return const Success(null);
     } catch (e) {
       return Failure('فشل تحديث حالة الإشعار: $e');
     }
   }

   @override
   Future<Result<List<domain.Major>>> getMajors() async {
    try {
      await _ensureInitialized();
      final q = await _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .limit(1000)
          .get();
      final set = <String>{};
      for (final d in q.docs) {
        final mid = (d.data()['majorId'] ?? '').toString();
        if (mid.isNotEmpty) set.add(mid);
      }
      final majors = set.map((id) => domain.Major(id: id, name: id)).toList();
      return Success(majors);
    } catch (e) {
      return Failure('خطأ في تحميل التخصصات: $e');
    }
  }

  @override
  Future<Result<List<String>>> getLevels() async {
    try {
      await _ensureInitialized();
      final q = await _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .limit(1000)
          .get();
      final set = <String>{};
      for (final d in q.docs) {
        final lvl = (d.data()['level'] ?? '').toString();
        if (lvl.isNotEmpty) set.add(lvl);
      }
      return Success(set.toList()..sort());
    } catch (e) {
      return Failure('خطأ في تحميل المراحل: $e');
    }
  }

  @override
  Future<Result<List<University>>> getUniversities({String? type}) async {
    try {
      await _ensureInitialized();
      // Expecting a Firestore collection named 'universities' when using Firebase backend.
      Query query = _db.collection('universities');
      if (type != null && type.trim().isNotEmpty) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return University(
          id: doc.id,
          name: (data['name'] ?? '').toString(),
          type: (data['type'] ?? '').toString(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }).toList();

      return Success(items);
    } catch (e) {
      return Failure('خطأ في تحميل الجامعات: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> getCourses({
    required String majorId,
    required String level,
    required domain.CourseTrack track,
  }) async {
    try {
      await _ensureInitialized();

      final qry = _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .where('majorId', isEqualTo: majorId)
          .where('level', isEqualTo: level)
          .where('track', isEqualTo: track.name);

      final qSnap = await qry.get();
      final uid = _uid;
      final subscribed = await _getActiveEnrollmentCourseIds(uid);
      final pending = await _getPendingEnrollRequestCourseIds(uid);

      final courses = qSnap.docs.map((d) {
        final m = d.data();
        final id = d.id;
        return domain.Course(
          id: id,
          title: (m['title'] ?? '') as String,
          instructorId: (m['instructorId'] ?? '') as String,
          majorId: (m['majorId'] ?? '') as String,
          level: (m['level'] ?? '') as String,
          track: domain.CourseTrack.values.byName((m['track'] ?? 'first') as String),
          coverUrl: (m['coverUrl'] ?? '') as String,
          lecturesCount: (m['lecturesCount'] ?? 0) as int,
          pendingActivation: pending.contains(id),
          isSubscribed: subscribed.contains(id),
        );
      }).toList();

      return Success(courses);
    } catch (e) {
      return Failure('خطأ في تحميل الكورسات: $e');
    }
  }

  @override
  Future<Result<List<domain.Lecture>>> getLectures(String courseId) async {
    try {
      await _ensureInitialized();

      final uid = _uid;
      final subscribedToCourse = uid != null &&
          (await _getActiveEnrollmentCourseIds(uid)).contains(courseId);

      Query q;
      if (courseId.isEmpty) {
        // Fallback used by video page: return a broad set (will be filtered by caller)
        q = _db.collectionGroup('lectures');
      } else {
        q = _db
            .collection('courseLectures')
            .doc(courseId)
            .collection('lectures')
            .orderBy('order');
      }

      final snap = await q.get();

      final items = <domain.Lecture>[];
      for (final d in snap.docs) {
        final m = d.data() as Map<String, dynamic>;
        final id = d.id;
        final isFree = (m['isFree'] ?? false) as bool;
        final String? explicitUrl = m['videoUrl'] as String?;
        final String? fileName = m['fileName'] as String?;

        String url = '';
        if (isFree) {
          if (explicitUrl != null && explicitUrl.isNotEmpty) {
            url = explicitUrl;
          } else if (fileName != null && courseId.isNotEmpty) {
            url = await _createSignedUrl(courseId: courseId, fileName: fileName);
          }
        } else if (subscribedToCourse) {
          if (explicitUrl != null && explicitUrl.isNotEmpty) {
            url = explicitUrl;
          } else if (fileName != null && courseId.isNotEmpty) {
            url = await _createSignedUrl(courseId: courseId, fileName: fileName);
          }
        }

        items.add(domain.Lecture(
          id: id,
          courseId: (m['courseId'] ?? courseId) as String,
          title: (m['title'] ?? '') as String,
          order: (m['order'] ?? 0) as int,
          isFree: isFree,
          videoUrl: url,
          duration: Duration(seconds: (m['duration'] ?? 0) as int),
        ));
      }

      // Sort by order when using collectionGroup
      items.sort((a, b) => a.order.compareTo(b.order));

      return Success(items);
    } catch (e) {
      return Failure('خطأ في تحميل المحاضرات: $e');
    }
  }

  @override
  Future<Result<domain.Course>> getCourse(String courseId) async {
    try {
      await _ensureInitialized();

      final doc = await _db.collection('courses').doc(courseId).get();
      if (!doc.exists) return const Failure('الكورس غير موجود');
      final m = doc.data()!;
      final uid = _uid;
      final subscribed = await _getActiveEnrollmentCourseIds(uid).catchError((_) => <String>{});
      final pending = await _getPendingEnrollRequestCourseIds(uid).catchError((_) => <String>{});

      final course = domain.Course(
        id: doc.id,
        title: (m['title'] ?? '') as String,
        instructorId: (m['instructorId'] ?? '') as String,
        majorId: (m['majorId'] ?? '') as String,
        level: (m['level'] ?? '') as String,
        track: domain.CourseTrack.values.byName((m['track'] ?? 'first') as String),
        coverUrl: (m['coverUrl'] ?? '') as String,
        lecturesCount: (m['lecturesCount'] ?? 0) as int,
        description: (m['description'] ?? '') as String,
        pendingActivation: pending.contains(doc.id),
        isSubscribed: subscribed.contains(doc.id),
      );

      return Success(course);
    } catch (e) {
      return Failure('خطأ في تحميل الكورس: $e');
    }
  }

  @override
  Future<Result<domain.Instructor>> getInstructor(String instructorId) async {
    try {
      await _ensureInitialized();

      // Try to read from an optional instructors collection
      final doc = await _db.collection('instructors').doc(instructorId).get();
      if (doc.exists) {
        final m = doc.data()!;
        return Success(domain.Instructor(
          id: doc.id,
          name: (m['name'] ?? 'المدرس') as String,
          avatarUrl: (m['avatarUrl'] ?? '') as String,
        ));
      }

      // Fallback placeholder
      return Success(domain.Instructor(
        id: instructorId,
        name: 'المدرس',
        avatarUrl: 'https://api.dicebear.com/7.x/initials/svg?seed=$instructorId',
      ));
    } catch (e) {
      return Failure('خطأ في تحميل المدرس: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> getLibraryCourses() async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) return const Success([]);

      final subscribed = await _getActiveEnrollmentCourseIds(uid);
      final pending = await _getPendingEnrollRequestCourseIds(uid);
      final ids = {...subscribed, ...pending};
      if (ids.isEmpty) return const Success([]);

      final courses = <domain.Course>[];
      for (final id in ids) {
        final r = await getCourse(id);
        r.when(
          success: (c) => courses.add(c),
          failure: (_) {},
        );
      }

      return Success(courses);
    } catch (e) {
      return Failure('خطأ في تحميل المكتبة: $e');
    }
  }

  @override
  Future<Result<void>> requestActivation(String courseId) async {
    try {
      await _ensureInitialized();
      final uid = _uid;
      if (uid == null) return const Failure('يرجى تسجيل الدخول أولاً');

      await _db.collection('requests').add({
        'uid': uid,
        'courseId': courseId,
        'type': 'enroll',
        'status': 'pending',
        'message': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } catch (e) {
      return Failure('خطأ في إرسال طلب الصلاحية: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> searchCourses(String query) async {
    try {
      await _ensureInitialized();
      if (query.trim().isEmpty) return const Success([]);

      // Simple title prefix search (requires index). For production use full-text via Algolia/Firestore + search service.
      final qSnap = await _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + '\uf8ff')
          .get();

      final uid = _uid;
      final subscribed = await _getActiveEnrollmentCourseIds(uid);
      final pending = await _getPendingEnrollRequestCourseIds(uid);

      final items = qSnap.docs.map((d) {
        final m = d.data();
        final id = d.id;
        return domain.Course(
          id: id,
          title: (m['title'] ?? '') as String,
          instructorId: (m['instructorId'] ?? '') as String,
          majorId: (m['majorId'] ?? '') as String,
          level: (m['level'] ?? '') as String,
          track: domain.CourseTrack.values.byName((m['track'] ?? 'first') as String),
          coverUrl: (m['coverUrl'] ?? '') as String,
          lecturesCount: (m['lecturesCount'] ?? 0) as int,
          pendingActivation: pending.contains(id),
          isSubscribed: subscribed.contains(id),
        );
      }).toList();

      return Success(items);
    } catch (e) {
      return Failure('خطأ في البحث: $e');
    }
  }

  // ---- Enrollment (Firebase) ----
  @override
  Future<Result<bool>> isUserEnrolledInCourse(String userId, String courseId) async {
    try {
      await _ensureInitialized();
      final q = await _db
          .collection('enrollments')
          .doc(userId)
          .collection('userCourses')
          .doc(courseId)
          .get();
      if (!q.exists) return const Success(false);
      final m = q.data();
      final active = (m?['active'] == true);
      if (!active) return const Success(false);
      // Optional expiry check
      final expiresAt = m?['expiresAt'];
      if (expiresAt is Timestamp) {
        if (expiresAt.toDate().isBefore(DateTime.now())) return const Success(false);
      }
      return const Success(true);
    } catch (e) {
      return Failure('فشل فحص حالة الصلاحية: $e');
    }
  }

  @override
  Future<Result<List<domain.Course>>> getUserActiveCourses(String userId) async {
    try {
      await _ensureInitialized();
      final now = DateTime.now();
      final q = await _db
          .collection('enrollments')
          .doc(userId)
          .collection('userCourses')
          .where('active', isEqualTo: true)
          .get();
      final ids = <String>{};
      for (final d in q.docs) {
        final m = d.data();
        final expiresAt = m['expiresAt'];
        if (expiresAt is Timestamp && expiresAt.toDate().isBefore(now)) continue;
        ids.add(d.id);
      }
      if (ids.isEmpty) return const Success([]);

      final list = <domain.Course>[];
      for (final id in ids) {
        final r = await getCourse(id);
        r.when(
          success: (c) => list.add(c.copyWith(isSubscribed: true)),
          failure: (_) {},
        );
      }
      return Success(list);
    } catch (e) {
      return Failure('فشل جلب الكورسات المتاحة: $e');
    }
  }

  @override
  Future<Result<List<String>>> getHeroImages() async {
    try {
      await _ensureInitialized();

      // Preferred: explicit hero collection maintained by admin (fields: imageUrl, order)
      final heroSnap = await _db
          .collection('hero')
          .orderBy('order', descending: false)
          .limit(10)
          .get();

      final images = <String>[];
      for (final d in heroSnap.docs) {
        final m = d.data();
        final url = (m['imageUrl'] ?? '').toString();
        if (url.isNotEmpty) images.add(url);
      }

      if (images.isNotEmpty) {
        return Success(images);
      }

      // Fallback: use coverUrl from latest active courses
      final coursesSnap = await _db
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      final covers = coursesSnap.docs
          .map((d) => (d.data()['coverUrl'] ?? '').toString())
          .where((u) => u.isNotEmpty)
          .toList();

      return Success(covers);
    } catch (e) {
      return Failure('خطأ في تحميل الصور: $e');
    }
  }

  // ------------ Helpers ------------

  Future<Set<String>> _getActiveEnrollmentCourseIds(String? uid) async {
    if (uid == null) return <String>{};
    final now = DateTime.now();
    final q = await _db
        .collection('enrollments')
        .doc(uid)
        .collection('userCourses')
        .where('active', isEqualTo: true)
        .get();

    final set = <String>{};
    for (final d in q.docs) {
      final m = d.data();
      final expiresAt = m['expiresAt'];
      if (expiresAt is Timestamp) {
        if (expiresAt.toDate().isBefore(now)) continue;
      }
      set.add(d.id);
    }
    return set;
  }

  Future<Set<String>> _getPendingEnrollRequestCourseIds(String? uid) async {
    if (uid == null) return <String>{};
    final q = await _db
        .collection('requests')
        .where('uid', isEqualTo: uid)
        .where('type', isEqualTo: 'enroll')
        .where('status', isEqualTo: 'pending')
        .get();
    return q.docs.map((d) => (d.data()['courseId'] ?? '').toString()).toSet();
  }

  Future<void> _tryRegisterFcmToken() async {
    // Messaging disabled in web preview; no-op.
    return;
  }

  Future<void> registerFcmToken({
    required String token,
    required String platform,
    Map<String, dynamic>? webSubscriptionInfo,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final ref = _db.collection('users').doc(uid).collection('fcmTokens').doc(token);
    await ref.set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': platform,
      if (webSubscriptionInfo != null) 'webSubscriptionInfo': webSubscriptionInfo,
    }, SetOptions(merge: true));
  }

  Future<String> _createSignedUrl({
    required String courseId,
    required String fileName,
  }) async {
    // Uses Firebase Storage download URL, relying on security rules
    final ref = _storage.ref('courses/$courseId/$fileName');
    final url = await ref.getDownloadURL();
    return url;
  }

  domain.User _userFromMap(Map<String, dynamic> m) {
    final rawTelegram = (m['telegramUsername'] ?? m['telegram_username'] ?? '').toString().trim();
    return domain.User(
      id: (m['id'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      governorate: (m['governorate'] ?? '') as String,
      university: (m['university'] ?? '') as String,
      birthDate: DateTime.tryParse((m['birthDate'] ?? '') as String) ?? DateTime.fromMillisecondsSinceEpoch(0),
      gender: _parseGender((m['gender'] ?? 'male') as String),
      telegramUsername: rawTelegram.isEmpty ? null : rawTelegram,
    );
  }

  domain.Gender _parseGender(String g) {
    return g == 'female' ? domain.Gender.female : domain.Gender.male;
  }

  String _mapFunctionsError(dynamic error) {
    // Handle both Cloud Functions-like errors and generic exceptions by checking strings
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission-denied')) {
      if (errorStr.contains('code_invalid')) return 'رمز التحقق خطأ';
      if (errorStr.contains('expired')) return 'انتهت صلاحية الرمز، يرجى طلب رمز جديد';
      return 'ليس لديك صلاحية لإتمام الطلب';
    }
    if (errorStr.contains('invalid-argument')) {
      return 'بيانات غير صحيحة. تحقق من رقم الهاتف والرمز.';
    }
    if (errorStr.contains('unauthenticated')) {
      return 'يرجى تسجيل الدخول أولاً';
    }
    if (errorStr.contains('not-found')) {
      return 'الخدمة غير متاحة حالياً';
    }
    if (errorStr.contains('deadline-exceeded') || errorStr.contains('timeout')) {
      return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
    }

    // Generic Firebase Auth errors
    if (errorStr.contains('firebase') && errorStr.contains('auth')) {
      if (errorStr.contains('invalid-custom-token')) {
        return 'رمز التحقق غير صالح';
      }
      if (errorStr.contains('custom-token-mismatch')) {
        return 'خطأ في التحقق من الهوية';
      }
    }

    // Network errors
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'تحقق من اتصال الإنترنت وحاول مرة أخرى';
    }

    // Default error message
    return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
  }
}
