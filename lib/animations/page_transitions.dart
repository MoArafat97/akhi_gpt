import 'package:flutter/material.dart';

/// ✨ MODERN PAGE TRANSITIONS with smooth animations
class ModernPageTransitions {
  
  // ✨ SLIDE TRANSITION - Smooth slide from right
  static Route<T> slideTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        
        final slideAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );
        
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // ✨ SCALE TRANSITION - Smooth scale with fade
  static Route<T> scaleTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutBack,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );
        
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  // ✨ FADE TRANSITION - Simple fade in/out
  static Route<T> fadeTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }

  // ✨ GLASSMORPHIC TRANSITION - Special transition with blur effect
  static Route<T> glassmorphicTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 500),
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );

        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// ✨ NAVIGATION HELPER with modern transitions
class ModernNavigator {
  
  // Navigate with slide transition
  static Future<T?> pushSlide<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push(
      ModernPageTransitions.slideTransition<T>(page),
    );
  }

  // Navigate with scale transition
  static Future<T?> pushScale<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push(
      ModernPageTransitions.scaleTransition<T>(page),
    );
  }

  // Navigate with fade transition
  static Future<T?> pushFade<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push(
      ModernPageTransitions.fadeTransition<T>(page),
    );
  }

  // Navigate with glassmorphic transition
  static Future<T?> pushGlassmorphic<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push(
      ModernPageTransitions.glassmorphicTransition<T>(page),
    );
  }

  // Replace with slide transition
  static Future<T?> pushReplacementSlide<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).pushReplacement(
      ModernPageTransitions.slideTransition<T>(page),
    );
  }
}

/// ✨ LOADING ANIMATIONS
class LoadingAnimations {
  
  // Pulsing dot animation
  static Widget pulsingDots({
    Color color = const Color(0xFF9C6644),
    double size = 8.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          tween: Tween<double>(begin: 0.3, end: 1.0),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: size * 0.2),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withValues(alpha: value),
                shape: BoxShape.circle,
              ),
            );
          },
          onEnd: () {
            // Restart animation
          },
        );
      }),
    );
  }

  // Spinning circle animation
  static Widget spinningCircle({
    Color color = const Color(0xFF9C6644),
    double size = 24.0,
    double strokeWidth = 2.5,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }
}
