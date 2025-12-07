import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/features/splash/splash_page.dart';
import 'package:grace_academy/features/onboarding/onboarding_page.dart';
import 'package:grace_academy/features/auth/login_page.dart';
import 'package:grace_academy/features/auth/otp_page.dart';
import 'package:grace_academy/features/auth/profile_form_page.dart';
import 'package:grace_academy/features/auth/register_page.dart';
import 'package:grace_academy/features/home/home_shell.dart';
import 'package:grace_academy/features/home/home_page.dart';
import 'package:grace_academy/features/search/search_page.dart';
import 'package:grace_academy/features/library/library_page.dart';
import 'package:grace_academy/features/account/account_page.dart';
import 'package:grace_academy/features/account/edit_account_page.dart';
import 'package:grace_academy/features/course/course_page.dart';
import 'package:grace_academy/features/player/video_player_page.dart';
import 'package:grace_academy/features/notifications/notifications_page.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const profileForm = '/profile-form';
  static const home = '/home';
  static const search = '/search';
  static const library = '/library';
  static const account = '/account';
  static const editAccount = '/account/edit';
  static const course = '/course';
  static const player = '/player';
  static const signup = '/signup';
  static const notifications = '/notifications';
}

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      
      // Auth flow
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) {
          String phone = '';
          String requestId = '';
          final extra = state.extra;
          if (extra is Map) {
            phone = (extra['phone'] ?? '') as String;
            requestId = (extra['requestId'] ?? '') as String;
          } else if (extra is String) {
            phone = extra;
          }
          return OTPPage(phone: phone, requestId: requestId);
        },
      ),
      GoRoute(
        path: AppRoutes.profileForm,
        name: 'profile-form',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return ProfileFormPage(phone: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const RegisterPage(),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.library,
            name: 'library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.account,
            name: 'account',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountPage(),
            ),
          ),
        ],
      ),
      
      // Notifications page
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Edit account
      GoRoute(
        path: AppRoutes.editAccount,
        name: 'edit-account',
        builder: (context, state) => const EditAccountPage(),
      ),
      
      // Course details (outside shell to have its own app bar)
      GoRoute(
        path: '${AppRoutes.course}/:courseId',
        name: 'course',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return CoursePage(courseId: courseId);
        },
      ),
      
      // Video player (outside shell, fullscreen)
      GoRoute(
        path: '${AppRoutes.player}/:lectureId',
        name: 'player',
        builder: (context, state) {
          final lectureId = state.pathParameters['lectureId']!;
          return VideoPlayerPage(lectureId: lectureId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('خطأ في التنقل: ${state.error}'),
          ],
        ),
      ),
    ),
  );
});

