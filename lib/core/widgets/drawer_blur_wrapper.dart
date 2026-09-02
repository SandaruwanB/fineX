import 'dart:ui';
import 'package:flutter/material.dart';

/// Smoothly blurs the page background content with a luxury frosted glass effect
/// whenever the navigation sidebar (Drawer) is opened.
class DrawerBlurWrapper extends StatelessWidget {
  final bool isDrawerOpen;
  final Widget child;
  final double maxBlur;

  const DrawerBlurWrapper({
    super.key,
    required this.isDrawerOpen,
    required this.child,
    this.maxBlur = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isDrawerOpen ? maxBlur : 0.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, blurSigma, childWidget) {
        final sigma = blurSigma > 0.01 ? blurSigma : 0.001;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: childWidget!,
        );
      },
      child: child,
    );
  }
}
