import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/features/home/home_controller.dart';
import 'package:grace_academy/features/home/widgets/course_card.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/widgets/app_logo.dart';

final libraryCoursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getLibraryCourses();
  
  return result.when(
    success: (courses) => courses,
    failure: (error) => throw Exception(error),
  );
});

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final libraryCoursesAsync = ref.watch(libraryCoursesProvider);
    final homeState = ref.watch(homeControllerProvider);

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: EduPulseColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 80,
                  color: EduPulseColors.textMain.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'يجب تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EduPulseColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'سجل دخولك لعرض المكتبة الخاصة بك',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: EduPulseColors.textMain.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text(AppStrings.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(libraryCoursesProvider.future);
          },
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
                      AppStrings.library,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              libraryCoursesAsync.when(
                data: (courses) => _buildLibraryContent(context, courses, homeState),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
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
                          'خطأ في تحميل المكتبة',
                          style: TextStyle(
                            color: EduPulseColors.error,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(libraryCoursesProvider),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent(BuildContext context, List<Course> courses, HomeState homeState) {
    if (courses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 80,
                color: EduPulseColors.textMain.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.noCoursesFound,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: EduPulseColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.noCoursesFoundDesc,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: EduPulseColors.textMain.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('تصفح الكورسات'),
              ),
            ],
          ),
        ),
      );
    }

    // Separate subscribed and pending courses
    final subscribedCourses = courses.where((c) => c.isSubscribed).toList();
    final pendingCourses = courses.where((c) => c.pendingActivation && !c.isSubscribed).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 16),
        
        // Subscribed courses section
        if (subscribedCourses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.subscribedCourses,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EduPulseColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...subscribedCourses.map((course) {
            final instructor = homeState.instructors[course.instructorId];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CourseCard(
                course: course,
                instructorName: instructor?.name ?? 'Unknown',
                onTap: () => context.push('${AppRoutes.course}/${course.id}'),
              ),
            );
          }).toList(),
        ],

        // Pending courses section
        if (pendingCourses.isNotEmpty) ...[
          if (subscribedCourses.isNotEmpty) const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.pendingActivation,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EduPulseColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...pendingCourses.map((course) {
            final instructor = homeState.instructors[course.instructorId];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CourseCard(
                course: course,
                instructorName: instructor?.name ?? 'Unknown',
                onTap: () => context.push('${AppRoutes.course}/${course.id}'),
              ),
            );
          }).toList(),
        ],

        const SizedBox(height: 100), // Bottom padding for navigation
      ]),
    );
  }
}
