import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/features/home/home_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/features/home/widgets/course_card.dart';
import 'package:grace_academy/features/home/widgets/major_selector.dart';
import 'package:grace_academy/features/home/widgets/track_selector.dart';
import 'package:grace_academy/features/home/widgets/hero_slider.dart';
import 'package:grace_academy/widgets/app_logo.dart';
import 'package:grace_academy/features/notifications/notifications_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _notificationsLoaded = false;

  void _showSupportOptions(BuildContext context) {
    final telegramUri = Uri.parse('https://t.me/Grace_academy1');
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'gracelearning.team@gmail.com',
      queryParameters: const {
        'subject': 'دعم Grace Academy',
        'body': 'مرحبا,\n\n',
      },
    );

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طرق التواصل مع الدعم',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text('تيليجرام'),
                  subtitle: const Text('@Grace_academy1'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final launched = await launchUrl(
                      telegramUri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('البريد الإلكتروني'),
                  subtitle: const Text('gracelearning.team@gmail.com'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final launched = await launchUrl(
                      emailUri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched) {
                      await launchUrl(emailUri, mode: LaunchMode.platformDefault);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomePage] build start');
    final homeState = ref.watch(homeControllerProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final notificationsState = ref.watch(notificationsControllerProvider).asData?.value;
    final unreadCount = notificationsState?.unreadCount ?? 0;

    // Load notifications once after first build
    if (isAuthenticated && !_notificationsLoaded) {
      _notificationsLoaded = true;
      Future.microtask(() {
        ref.read(notificationsControllerProvider.notifier).load();
      });
    }

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
          color: EduPulseColors.primary,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                title: Row(
                  children: [
                    const AppLogo(size: 40),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (isAuthenticated) ...[
                    IconButton(
                      icon: const Icon(Icons.support_agent_outlined),
                      tooltip: AppStrings.support,
                      onPressed: () => _showSupportOptions(context),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () => context.push(AppRoutes.notifications),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: EduPulseColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('تسجيل الدخول'),
                    ),
                  ],
                ],
              ),

              // Content
              if (homeState.isLoading && homeState.courses.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (homeState.error != null)
                SliverFillRemaining(
                  child: Center(
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
                          homeState.error!,
                          style: TextStyle(
                            color: EduPulseColors.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(homeControllerProvider.notifier).refresh(),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),

                    // Major and Level selectors
                    MajorLevelSelector(
                      majors: homeState.majors,
                      levels: homeState.levelsForSelectedMajor(),
                      selectedMajorId: homeState.selectedMajorId,
                      selectedLevel: homeState.selectedLevel,
                      onMajorChanged: (majorId) =>
                          ref.read(homeControllerProvider.notifier).selectMajor(majorId),
                      onLevelChanged: (level) =>
                          ref.read(homeControllerProvider.notifier).selectLevel(level),
                    ),

                    const SizedBox(height: 24),

                    // Hero slider
                    if (homeState.heroImages.isNotEmpty)
                      HeroSlider(images: homeState.heroImages),

                    const SizedBox(height: 24),

                    // Track selector
                    TrackSelector(
                      selectedTrack: homeState.selectedTrack,
                      onTrackChanged: (track) =>
                          ref.read(homeControllerProvider.notifier).selectTrack(track),
                    ),

                    const SizedBox(height: 16),

                    // Courses grid
                    if (homeState.courses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد كورسات متاحة',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      CoursesGrid(
                        courses: homeState.courses,
                        instructors: homeState.instructors,
                      ),

                    const SizedBox(height: 100), // Bottom padding for navigation
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoursesGrid extends StatelessWidget {
  final List<Course> courses;
  final Map<String, dynamic> instructors;

  const CoursesGrid({
    super.key,
    required this.courses,
    required this.instructors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: courses.map((course) {
          final instructor = instructors[course.instructorId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CourseCard(
              course: course,
              instructorName: instructor?.name ?? 'Unknown',
              onTap: () => context.push('${AppRoutes.course}/${course.id}'),
            ),
          );
        }).toList(),
      ),
    );
  }
}