import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';

/// A back button that "does the right thing":
/// - If there is a page to pop, it pops.
/// - Otherwise, it navigates to home.
///
/// Styled as a circular icon with subtle background to remain visible
/// over images or dark/light headers.
class SmartBackButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final EdgeInsetsGeometry padding;

  const SmartBackButton({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.padding = const EdgeInsets.all(8),
  });

  bool _canPop(BuildContext context) {
    final navigator = Navigator.of(context);
    return navigator.canPop();
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? Colors.black.withValues(alpha: 0.35);
    final Color ic = iconColor ?? Colors.white;

    return Padding(
      padding: padding,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (_canPop(context)) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconTheme(
                data: IconThemeData(color: ic, size: 22),
                child: const BackButtonIcon(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
