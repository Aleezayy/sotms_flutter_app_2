import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../main.dart';
import '../widgets/app_background_wrapper.dart';
import 'theme_selection_screen.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Real-Time Tracking",
      "description":
          "Track your entire fleet of oil tankers in real-time with high-precision GPS monitoring.",
    },
    {
      "title": "Intelligent Alerts",
      "description":
          "Receive instant notifications for critical sensor changes like temperature, pressure, and fuel levels.",
    },
    {
      "title": "Driver Behaviour",
      "description":
          "Monitor and analyze driver behaviour, including overspeeding and harsh braking, to ensure safety.",
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ThemeSelectionScreen(themeProvider: themeProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackgroundWrapper(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isShort = constraints.maxHeight < 680;
              final buttonWidth = constraints.maxWidth < 380 ? 260.0 : 290.0;
              final buttonHeight = constraints.maxWidth < 380 ? 62.0 : 68.0;

              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (value) {
                        setState(() {
                          _currentPage = value;
                        });
                      },
                      itemCount: onboardingData.length,
                      itemBuilder: (context, index) => OnboardingContent(
                        title: onboardingData[index]["title"]!,
                        description: onboardingData[index]["description"]!,
                        index: index,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, isShort ? 18 : 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            onboardingData.length,
                            (index) => buildDot(index: index, isDark: isDark),
                          ),
                        ),
                        SizedBox(height: isShort ? 18 : 28),
                        SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: CustomButton(
                            text: _currentPage == onboardingData.length - 1
                                ? "Get Started"
                                : "Continue",
                            onPressed: () {
                              if (_currentPage == onboardingData.length - 1) {
                                _completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            },
                            icon: _currentPage == onboardingData.length - 1
                                ? Icons.check
                                : Icons.arrow_forward_ios,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildDot({int? index, required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? (isDark ? AppTheme.primary : AppTheme.lightPrimary)
            : (isDark ? AppTheme.textTertiary : AppTheme.lightTextSecondary).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String description;
  final int index;
  final bool isDark;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    required this.index,
    required this.isDark,
  });

  IconData _getIcon() {
    switch (index) {
      case 0:
        return Icons.map_outlined;
      case 1:
        return Icons.warning_amber_rounded;
      case 2:
        return Icons.speed;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final isSmall = size.shortestSide < 380 || constraints.maxHeight < 520;
        final iconSize = isSmall ? 68.0 : 100.0;
        final iconPadding = isSmall ? 26.0 : 40.0;
        final primaryColor = isDark ? AppTheme.primary : AppTheme.lightPrimary;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 18 : 24,
            vertical: isSmall ? 12 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.surface : Colors.white,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.24),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.18),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIcon(),
                    size: iconSize,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: isSmall ? 32 : 48),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmall ? 24 : 28,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
