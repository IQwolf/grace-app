import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/theme.dart';
// Removed flutter_svg in favor of using the PNG logo asset

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _bgController;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      icon: Icons.school_rounded,
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
    ),
    OnboardingData(
      icon: Icons.security_rounded,
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
    ),
    OnboardingData(
      icon: Icons.flash_on_rounded,
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))..repeat(reverse: true);
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) context.go(AppRoutes.home);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 360), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[OnboardingPage] build');
    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _bgController,
          builder: (context, _) {
            final t = _bgController.value;
            return Stack(
              children: [
                // Animated decorative background
                Positioned(
                  top: -80 + 10 * math.sin(2 * math.pi * t),
                  left: -40 + 12 * math.cos(2 * math.pi * (t + 0.2)),
                  child: _DecorativeBlob(
                    size: 220,
                    colors: [
                      EduPulseColors.primary.withValues(alpha: 0.25),
                      EduPulseColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -100 + 10 * math.cos(2 * math.pi * (t + 0.4)),
                  right: -60 + 10 * math.sin(2 * math.pi * (t + 0.4)),
                  child: _DecorativeBlob(
                    size: 320,
                    colors: [
                      EduPulseColors.primaryDark.withValues(alpha: 0.20),
                      EduPulseColors.primaryDark.withValues(alpha: 0.04),
                    ],
                  ),
                ),

                Column(
                  children: [
                    // Top bar with Skip and Hero logo for continuity
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'app.logo',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/logononbackground.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _completeOnboarding,
                            child: Text(
                              'تخطي',
                              style: TextStyle(color: EduPulseColors.textMain.withValues(alpha: 0.7), fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      key: const ValueKey('onboarding.pageview'),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double page = 0;
                              if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                page = _pageController.page ?? _pageController.initialPage.toDouble();
                              } else {
                                page = _currentPage.toDouble();
                              }
                              final delta = (index - page);
                              return Transform.translate(
                                offset: Offset(30 * delta, 0),
                                child: Transform.scale(
                                  scale: 1 - 0.05 * delta.abs(),
                                  child: Opacity(opacity: (1 - 0.3 * delta.abs()).clamp(0.0, 1.0), child: OnboardingSlide(data: _pages[index], delta: delta)),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Indicators
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _ExpandingDot(isActive: _currentPage == index),
                        ),
                      ),
                    ),

                    // Bottom navigation
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Row(
                        children: [
                          if (_currentPage > 0)
                            TextButton(
                              onPressed: _previousPage,
                              child: Text(
                                AppStrings.previous,
                                style: TextStyle(color: EduPulseColors.textMain.withValues(alpha: 0.7)),
                              ),
                            )
                          else
                            const SizedBox(width: 84),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _nextPage,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _currentPage == _pages.length - 1 ? AppStrings.start : AppStrings.next,
                                    key: ValueKey(_currentPage == _pages.length - 1),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _currentPage == _pages.length - 1 ? Icons.check_circle_rounded : Icons.arrow_back_rounded,
                                    key: ValueKey(_currentPage == _pages.length - 1),
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingData data;
  final double delta; // how far from center page (0 = focused)

  const OnboardingSlide({super.key, required this.data, required this.delta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                key: const ValueKey('onboarding.slide.card'),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon in gradient bubble with subtle parallax
                      Transform.translate(
                        offset: Offset(0, 8 * delta),
                        child: Transform.scale(
                          scale: 1 - 0.06 * delta.abs(),
                          child: Container(
                            width: constraints.maxWidth * 0.38,
                            height: constraints.maxWidth * 0.38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  EduPulseColors.primary.withValues(alpha: 0.85),
                                  EduPulseColors.primaryDark.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1000),
                              boxShadow: [
                                BoxShadow(color: EduPulseColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: Offset(0, 12)),
                              ],
                            ),
                            child: Center(
                              child: Icon(data.icon, size: constraints.maxWidth * 0.20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      Transform.translate(
                        offset: Offset(16 * delta, 0),
                        child: Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: EduPulseColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Transform.translate(
                        offset: Offset(-12 * delta, 0),
                        child: Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: EduPulseColors.textMain.withValues(alpha: 0.8),
                                height: 1.7,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingData({required this.icon, required this.title, required this.description});
}

class _DecorativeBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _DecorativeBlob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        gradient: RadialGradient(colors: colors, center: Alignment.center, radius: 0.85),
      ),
    );
  }
}

class _ExpandingDot extends StatelessWidget {
  final bool isActive;
  const _ExpandingDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 28 : 10,
      decoration: BoxDecoration(
        color: isActive ? EduPulseColors.primary : EduPulseColors.divider,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}