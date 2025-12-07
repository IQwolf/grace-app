import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grace_academy/utils/image_utils.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/lecture.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/features/home/home_controller.dart';
import 'package:grace_academy/features/library/library_page.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/widgets/smart_back_button.dart';

final courseProvider = FutureProvider.family<Course, String>((ref, courseId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getCourse(courseId);
  
  return result.when(
    success: (course) => course,
    failure: (error) => throw Exception(error),
  );
});

final lecturesProvider = FutureProvider.family<List<Lecture>, String>((ref, courseId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getLectures(courseId);
  
  return result.when(
    success: (lectures) => lectures,
    failure: (error) => throw Exception(error),
  );
});

final instructorProvider = FutureProvider.family<Instructor, String>((ref, instructorId) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getInstructor(instructorId);
  
  return result.when(
    success: (instructor) => instructor,
    failure: (error) => throw Exception(error),
  );
});

class CoursePage extends ConsumerStatefulWidget {
  final String courseId;

  const CoursePage({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends ConsumerState<CoursePage> with WidgetsBindingObserver {
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.invalidate(courseProvider(widget.courseId));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check enrollment when returning to the app
      ref.invalidate(courseProvider(widget.courseId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: courseAsync.when(
        data: (course) => _buildCourseContent(context, ref, course, isAuthenticated),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: EduPulseColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'خطأ في تحميل الكورس',
                style: TextStyle(
                  color: EduPulseColors.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(courseProvider(widget.courseId));
                  ref.invalidate(lecturesProvider(widget.courseId));
                },
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseContent(BuildContext context, WidgetRef ref, Course course, bool isAuthenticated) {
    final lecturesAsync = ref.watch(lecturesProvider(widget.courseId));
    final instructorAsync = ref.watch(instructorProvider(course.instructorId));

    return CustomScrollView(
      slivers: [
        // Course header
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: EduPulseColors.primaryDark,
          leading: const SmartBackButton(),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                ImageUtils.safeNetworkImage(
                  course.coverUrl,
                  fit: BoxFit.cover,
                ),
                // Subtle top gradient for better contrast with the back button
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Course info
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: EduPulseColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course title
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: EduPulseColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Instructor info
                instructorAsync.when(
                  data: (instructor) => Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: ImageUtils.providerOrPlaceholder(instructor.avatarUrl),
                        backgroundColor: EduPulseColors.primary.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        instructor.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: EduPulseColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 44),
                  error: (_, __) => const SizedBox(height: 44),
                ),

                const SizedBox(height: 16),

                // Course stats
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.play_circle_outline,
                      label: '${course.lecturesCount} ${AppStrings.lecturesCount}',
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.schedule,
                      label: course.level,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Description
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EduPulseColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: EduPulseColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوصف',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  (course.description.isNotEmpty ? course.description : 'لا يوجد وصف متاح لهذا الكورس.'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EduPulseColors.textMain.withValues(alpha: 0.9),
                      ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),

        // Lectures list
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EduPulseColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: EduPulseColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'المحاضرات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: EduPulseColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                lecturesAsync.when(
                  data: (lectures) => Column(
                    children: lectures.map((lecture) => _buildLectureTile(
                      context,
                      ref,
                      lecture,
                      course,
                      isAuthenticated,
                    )).toList(),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, st) {
                    debugPrint('[CoursePage] lectures error=$err');
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'خطأ في تحميل المحاضرات',
                          style: TextStyle(color: EduPulseColors.error),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EduPulseColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: EduPulseColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: EduPulseColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLectureTile(
    BuildContext context,
    WidgetRef ref,
    Lecture lecture,
    Course course,
    bool isAuthenticated,
  ) {
    final isLocked = !lecture.isFree && !course.isSubscribed;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: lecture.isFree 
              ? Colors.green.withValues(alpha: 0.1)
              : isLocked 
                  ? Colors.grey.withValues(alpha: 0.1)
                  : EduPulseColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isLocked ? Icons.lock : Icons.play_arrow,
          color: lecture.isFree 
              ? Colors.green
              : isLocked 
                  ? Colors.grey
                  : EduPulseColors.primary,
        ),
      ),
      title: Text(
        lecture.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isLocked 
              ? EduPulseColors.textMain.withValues(alpha: 0.5)
              : EduPulseColors.textMain,
        ),
      ),
      subtitle: Row(
        children: [
          Text(
            lecture.formattedDuration,
            style: TextStyle(
              color: isLocked 
                  ? EduPulseColors.textMain.withValues(alpha: 0.3)
                  : EduPulseColors.textMain.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          if (lecture.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppStrings.freeLecture,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else if (isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                AppStrings.locked,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      trailing: isLocked ? null : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _handleLectureTap(context, ref, lecture, course, isAuthenticated, isLocked),
    );
  }

  Future<void> _handleLectureTap(
    BuildContext context,
    WidgetRef ref,
    Lecture lecture,
    Course course,
    bool isAuthenticated,
    bool isLocked,
  ) async {
    if (!isLocked) {
      // Play lecture
      context.push('${AppRoutes.player}/${lecture.id}');
      return;
    }

    if (!isAuthenticated) {
      // Go to login
      context.go(AppRoutes.login);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null || user.phone.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.missingPhoneForTelegram),
          backgroundColor: EduPulseColors.error,
        ),
      );
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    String? telegramUsername = user.telegramUsername;
    final usernameLookup = await apiClient.getTelegramUsername(phoneNumber: user.phone);
    usernameLookup.when(
      success: (value) {
        if (value != null && value.isNotEmpty) {
          telegramUsername = value;
        }
      },
      failure: (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: EduPulseColors.error,
            ),
          );
        }
      },
    );

    String? usernameCandidate = telegramUsername;
    String? enteredUsername;
    while (true) {
      if (!context.mounted) return;
      final input = await _askForTelegramUsername(context, initialValue: usernameCandidate);
      if (input == null) {
        return;
      }
      if (!context.mounted) return;
      final action = await _confirmTelegramUsername(context, input);
      if (action == _TelegramConfirmAction.confirm) {
        enteredUsername = input;
        break;
      }
      if (action == _TelegramConfirmAction.edit) {
        usernameCandidate = input;
        continue;
      }
      return;
    }

    if (enteredUsername == null) {
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final updateResult = await apiClient.updateTelegramUsername(
      phoneNumber: user.phone,
      telegramUsername: enteredUsername,
    );

    if (updateResult is Failure<void>) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updateResult.error),
            backgroundColor: EduPulseColors.error,
          ),
        );
      }
      return;
    }

    await ref.read(authControllerProvider.notifier).fetchCurrentUser();

    final activationResult = await apiClient.requestActivation(course.id);

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      activationResult.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.requestSentMessage),
              backgroundColor: EduPulseColors.primary,
            ),
          );
          // Refresh course page and other providers
          ref.invalidate(courseProvider(widget.courseId));
          ref.invalidate(lecturesProvider(widget.courseId));
          // Refresh library and home pages
          ref.invalidate(libraryCoursesProvider);
          ref.read(homeControllerProvider.notifier).refresh();
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: EduPulseColors.error,
            ),
          );
        },
      );
    }
  }

  Future<String?> _askForTelegramUsername(BuildContext context, {String? initialValue}) async {
    String value = initialValue ?? '';
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(AppStrings.telegramUsernameTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.telegramUsernamePrompt),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: value,
                    autofocus: true,
                    textDirection: TextDirection.ltr,
                    onChanged: (newValue) {
                      value = newValue;
                      if (errorText != null) {
                        setState(() => errorText = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.telegramUsernameHint,
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final trimmed = value.trim();
                    if (trimmed.isEmpty || trimmed.contains(' ')) {
                      setState(() => errorText = AppStrings.telegramUsernameRequired);
                      return;
                    }
                    Navigator.of(dialogContext).pop(trimmed);
                  },
                  child: Text(
                    AppStrings.next,
                    style: TextStyle(color: EduPulseColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<_TelegramConfirmAction> _confirmTelegramUsername(BuildContext context, String username) async {
    final result = await showDialog<_TelegramConfirmAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.telegramUsernameConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.telegramUsernameConfirmMessage),
              const SizedBox(height: 8),
              Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_TelegramConfirmAction.cancel),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_TelegramConfirmAction.edit),
              child: const Text(AppStrings.edit),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_TelegramConfirmAction.confirm),
              child: Text(
                AppStrings.yesImSure,
                style: TextStyle(color: EduPulseColors.primary),
              ),
            ),
          ],
        );
      },
    );
    return result ?? _TelegramConfirmAction.cancel;
  }
}

enum _TelegramConfirmAction { confirm, edit, cancel }