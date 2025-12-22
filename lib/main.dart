import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/secure_flag.dart';
import 'core/config.dart';
import 'package:grace_academy/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error logging to help diagnose preview-start issues
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Initialize Firebase with timeout so startup can't hang
  try {
    debugPrint('[Main] Firebase.initializeApp start');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    debugPrint('[Main] Firebase.initializeApp done');
  } on TimeoutException catch (_) {
    debugPrint('[Main] Firebase init timed out after 8s — continuing without blocking UI');
  } catch (e, st) {
    debugPrint('[Main] Firebase init failed: $e');
    debugPrintStack(stackTrace: st);
  }

  // Do not enable FLAG_SECURE globally at startup.
  // Individual pages (e.g., VideoPlayerPage) will opt-in when needed.
  // If you want to re-enable globally, call: await SecureFlag.enableSecure();
  
  // Enable edge-to-edge mode for Android 15+ compatibility
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  debugPrint('[Main] runApp');
  runApp(
    const ProviderScope(
      child: EduPulseApp(),
    ),
  );
}

class EduPulseApp extends ConsumerWidget {
  const EduPulseApp({super.key});

  static bool _didScheduleNotificationInit = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Grace Academy',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      
      // Arabic RTL support
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [
        Locale('ar'),
        Locale('ar', 'IQ'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // RTL text direction
      builder: (context, child) {
        // Initialize FCM & notifications once (deferred to post-frame to avoid build-time context issues)
        if (!_didScheduleNotificationInit) {
          _didScheduleNotificationInit = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              try {
                ref.read(notificationServiceProvider).initialize(context);
              } catch (e) {
                debugPrint('[Main] Notification initialize error: $e');
              }
            }
          });
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      routerConfig: router,
    );
  }
}