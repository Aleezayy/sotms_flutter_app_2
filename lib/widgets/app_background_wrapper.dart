import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBackgroundWrapper extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const AppBackgroundWrapper({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      height: double.infinity,
      color: theme.scaffoldBackgroundColor, // Fallback color
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Image.asset(
                isDark ? AppTheme.backgroundPath : AppTheme.lightBackgroundPath,
                key: ValueKey(isDark),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        // Overlay / Gradient
        if (showOverlay)
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.05),
                          theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
                        ],
                      ),
              ),
            ),
          ),
        // The actual content
        child,
      ],
    ),
    );
  }
}
