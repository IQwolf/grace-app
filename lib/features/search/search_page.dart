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

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  List<Course> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _isSearching = true);

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.searchCourses(query);

    if (!mounted) return;

    result.when(
      success: (courses) {
        setState(() {
          _searchResults = courses;
          _isSearching = false;
        });
      },
      failure: (error) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: EduPulseColors.error,
          ),
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _lastQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EduPulseColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.search,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: EduPulseColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _performSearch(value);
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: AppStrings.searchCourses,
                  prefixIcon: Icon(
                    Icons.search,
                    color: EduPulseColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Results
            Expanded(
              child: _buildSearchResults(homeState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(HomeState homeState) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: EduPulseColors.textMain.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'ابدأ البحث عن الكورسات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك البحث بعنوان الكورس أو اسم المدرس',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: EduPulseColors.textMain.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noResultsDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final course = _searchResults[index];
        final instructor = homeState.instructors[course.instructorId];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CourseCard(
            course: course,
            instructorName: instructor?.name ?? 'Unknown',
            onTap: () => context.push('${AppRoutes.course}/${course.id}'),
          ),
        );
      },
    );
  }
}