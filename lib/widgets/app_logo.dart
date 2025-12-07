import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool rounded;
  final Color? background;

  const AppLogo({super.key, this.size = 40, this.rounded = false, this.background});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/logononbackground.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'App Logo',
    );

    if (!rounded && background == null) return logo;

    return Container(
      width: size + 10,
      height: size + 10,
      decoration: BoxDecoration(
        color: background ?? Colors.transparent,
        borderRadius: BorderRadius.circular(rounded ? (size + 10) / 4 : 8),
        boxShadow: background == null
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }
}
