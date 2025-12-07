import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/course.dart';
import 'package:grace_academy/data/models/instructor.dart';
import 'package:grace_academy/data/models/major.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';

// Home state
class HomeState {
  final List<Major> majors;
  final Map<String, List<String>> levelsByMajor;
  final String? selectedMajorId;
  final String? selectedLevel;
  final CourseTrack selectedTrack;
  final List<Course> courses;
  final List<String> heroImages;
  final Map<String, Instructor> instructors;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.majors = const [],
    this.levelsByMajor = const {},
    this.selectedMajorId,
    this.selectedLevel,
    this.selectedTrack = CourseTrack.first,
    this.courses = const [],
    this.heroImages = const [],
    this.instructors = const {},
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<Major>? majors,
    Map<String, List<String>>? levelsByMajor,
    String? selectedMajorId,
    String? selectedLevel,
    CourseTrack? selectedTrack,
    List<Course>? courses,
    List<String>? heroImages,
    Map<String, Instructor>? instructors,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      majors: majors ?? this.majors,
      levelsByMajor: levelsByMajor ?? this.levelsByMajor,
      selectedMajorId: selectedMajorId ?? this.selectedMajorId,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedTrack: selectedTrack ?? this.selectedTrack,
      courses: courses ?? this.courses,
      heroImages: heroImages ?? this.heroImages,
      instructors: instructors ?? this.instructors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<String> levelsForSelectedMajor() {
    final id = selectedMajorId;
    if (id == null) return const [];
    return levelsByMajor[id] ?? const [];
  }
}

// Home controller
class HomeController extends Notifier<HomeState> {
  late final ApiClient _apiClient = ref.read(apiClientProvider);

  @override
  HomeState build() {
    // Start async initialization without blocking build
    Future.microtask(_initialize);
    return const HomeState();
  }
  
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadMajorsWithLevels(),
        _loadHeroImages(),
      ]);
      await _loadSavedSelections();
      
      if (state.selectedMajorId != null && state.selectedLevel != null) {
        await _loadCourses();
      }
      // Finish loading after successful initialization
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'خطأ في تحميل البيانات: $e',
      );
    }
  }

  Future<void> _loadMajorsWithLevels() async {
    final result = await _apiClient.getMajorsWithLevels();
    result.when(
      success: (items) {
        final majors = items.map((e) => Major(id: e.id, name: e.name)).toList();
        final map = {for (final e in items) e.id: e.levels};
        state = state.copyWith(majors: majors, levelsByMajor: map);
      },
      failure: (error) => state = state.copyWith(error: error),
    );
  }

  Future<void> _loadHeroImages() async {
    final result = await _apiClient.getHeroImages();
    result.when(
      success: (images) => state = state.copyWith(heroImages: images),
      failure: (_) {},
    );
  }

  Future<void> _loadSavedSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMajorId = prefs.getString('last_major_id');
      final savedLevel = prefs.getString('last_level');

      String? majorId = savedMajorId;
      if (majorId == null || !state.majors.any((m) => m.id == majorId)) {
        majorId = state.majors.isNotEmpty ? state.majors.first.id : null;
      }

      // Validate saved level against the chosen major's levels
      final levels = majorId != null ? (state.levelsByMajor[majorId] ?? const []) : const [];
      String? level = (savedLevel != null && levels.contains(savedLevel))
          ? savedLevel
          : (levels.isNotEmpty ? levels.first : null);

      state = state.copyWith(
        selectedMajorId: majorId,
        selectedLevel: level,
      );
    } catch (_) {
      final mid = state.majors.isNotEmpty ? state.majors.first.id : null;
      final lv = mid != null ? (state.levelsByMajor[mid] ?? const []) : const [];
      state = state.copyWith(
        selectedMajorId: mid,
        selectedLevel: lv.isNotEmpty ? lv.first : null,
      );
    }
  }
  
  Future<void> _loadCourses() async {
    if (state.selectedMajorId == null || state.selectedLevel == null) return;

    final result = await _apiClient.getCourses(
      majorId: state.selectedMajorId!,
      level: state.selectedLevel!,
      track: state.selectedTrack,
    );

    await result.when(
      success: (courses) async {
        state = state.copyWith(courses: courses);
        await _loadInstructors(courses);
      },
      failure: (error) async {
        state = state.copyWith(error: error);
      },
    );
  }

  Future<void> _loadInstructors(List<Course> courses) async {
    final instructorIds = courses.map((c) => c.instructorId).toSet();
    final Map<String, Instructor> instructors = {...state.instructors};

    for (final instructorId in instructorIds) {
      if (!instructors.containsKey(instructorId)) {
        final result = await _apiClient.getInstructor(instructorId);
        result.when(
          success: (instructor) => instructors[instructorId] = instructor,
          failure: (_) {},
        );
      }
    }

    state = state.copyWith(instructors: instructors);
  }

  Future<void> selectMajor(String majorId) async {
    if (majorId == state.selectedMajorId) return;
    // If current level not valid for new major, pick first available
    final levels = state.levelsByMajor[majorId] ?? const [];
    final String? nextLevel = levels.isNotEmpty ? levels.first : null;
    state = state.copyWith(selectedMajorId: majorId, selectedLevel: nextLevel, isLoading: true);
    await _saveSelections();
    await _loadCourses();
    state = state.copyWith(isLoading: false);
  }
  
  Future<void> selectLevel(String level) async {
    if (level == state.selectedLevel) return;
    state = state.copyWith(selectedLevel: level, isLoading: true);
    await _saveSelections();
    await _loadCourses();
    state = state.copyWith(isLoading: false);
  }

  Future<void> selectTrack(CourseTrack track) async {
    if (track == state.selectedTrack) return;
    state = state.copyWith(selectedTrack: track, isLoading: true);
    await _loadCourses();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _saveSelections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.selectedMajorId != null) {
        await prefs.setString('last_major_id', state.selectedMajorId!);
      }
      if (state.selectedLevel != null) {
        await prefs.setString('last_level', state.selectedLevel!);
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _initialize();
  }

  Instructor? getInstructor(String instructorId) => state.instructors[instructorId];

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for home controller
final homeControllerProvider = NotifierProvider<HomeController, HomeState>(HomeController.new);