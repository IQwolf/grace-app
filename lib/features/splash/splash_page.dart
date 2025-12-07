import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _bgController;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(duration: const Duration(milliseconds: 1100), vsync: this);
    _bgController = AnimationController(duration: const Duration(milliseconds: 6000), vsync: this)..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);
    _scaleIn = Tween<double>(begin: 0.92, end: 1).animate(CurvedAnimation(parent: _introController, curve: Curves.elasticOut));
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _introController.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Give time for the intro animation to play nicely
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('onboarding_seen') ?? false;
      if (hasSeenOnboarding) {
        debugPrint('[Splash] Navigate -> Home');
        context.go(AppRoutes.home);
      } else {
        debugPrint('[Splash] Navigate -> Onboarding');
        context.go(AppRoutes.onboarding);
      }
    } catch (_) {
      if (mounted) context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SplashPage] build');
    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          final c1 = Color.lerp(EduPulseColors.background, Colors.white, 0.5 + 0.4 * math.sin(2 * math.pi * (t + 0.15)))!;
          final c2 = Color.lerp(EduPulseColors.primary.withValues(alpha: 0.2), EduPulseColors.primaryDark.withValues(alpha: 0.25), 0.5 + 0.5 * math.sin(2 * math.pi * (t + 0.65)))!;
          final beginAlign = Alignment(0.8 - 1.6 * t, -0.6 + 1.2 * t);
          final endAlign = Alignment(-0.8 + 1.6 * t, 0.6 - 1.2 * t);

          return Stack(
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: beginAlign,
                    end: endAlign,
                    colors: [c1, c2],
                  ),
                ),
              ),

              // Floating blobs
              _AnimatedBlob(
                size: 220,
                color: EduPulseColors.primary.withValues(alpha: 0.20),
                x: 0.18 + 0.03 * math.sin(2 * math.pi * t),
                y: -0.12 + 0.04 * math.cos(2 * math.pi * t),
              ),
              _AnimatedBlob(
                size: 300,
                color: EduPulseColors.primaryDark.withValues(alpha: 0.18),
                x: 0.85 + 0.02 * math.sin(2 * math.pi * (t + 0.4)),
                y: 0.85 + 0.03 * math.cos(2 * math.pi * (t + 0.4)),
              ),

              // Center content
              Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(
                    scale: _scaleIn,
                    child: SlideTransition(
                      position: _slideIn,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with Hero for transition to onboarding
                          Hero(
                            tag: 'app.logo',
                            child: Image.asset(
                              'assets/images/logononbackground.png',
                              width: 160,
                              height: 160,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            AppStrings.appName,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: EduPulseColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: 0.9,
                            child: Text(
                              'تعليم أسهل… مستقبل أفضل',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: EduPulseColors.textMain.withValues(alpha: 0.75),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SubtleProgressBar(progress: _fadeIn.value),
                        ],
                      ),
                    ),
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

class _AnimatedBlob extends StatelessWidget {
  final double size;
  final Color color;
  // x and y are in -1..1 alignment space
  final double x;
  final double y;

  const _AnimatedBlob({required this.size, required this.color, required this.x, required this.y});

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(x * 2 - 1, y * 2 - 1);
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: const Offset(0, 0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 60, spreadRadius: 10)],
          ),
        ),
      ),
    );
  }
}

class _SubtleProgressBar extends StatelessWidget {
  final double progress; // 0..1
  const _SubtleProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withValues(alpha: 0.7);
    final fg = EduPulseColors.primary;
    return Container(
      width: 160,
      height: 6,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 160 * progress.clamp(0, 1),
        height: 6,
        decoration: BoxDecoration(
          color: fg,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [BoxShadow(color: fg.withValues(alpha: 0.35), blurRadius: 12, offset: Offset(0, 6))],
        ),
      ),
    );
  }
}