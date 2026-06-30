import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'sign_in_screen.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ThemeSelectionScreen({super.key, required this.themeProvider});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  ThemeMode _selectedMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.themeProvider.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background - adapt based on selection
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey(_selectedMode),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    _selectedMode == ThemeMode.dark ? AppTheme.backgroundPath : AppTheme.lightBackgroundPath,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: _selectedMode == ThemeMode.dark 
                    ? Colors.black.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Choose Theme Mode",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.displaySmall?.color,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select the look that fits your workflow",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Mode Selection Cards
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeModeCard(
                            title: "Dark Mode",
                            icon: Icons.dark_mode_rounded,
                            isSelected: _selectedMode == ThemeMode.dark,
                            isDark: true,
                            onTap: () => setState(() => _selectedMode = ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ThemeModeCard(
                            title: "Light Mode",
                            icon: Icons.light_mode_rounded,
                            isSelected: _selectedMode == ThemeMode.light,
                            isDark: false,
                            onTap: () => setState(() => _selectedMode = ThemeMode.light),
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    const SizedBox(height: 24),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await widget.themeProvider.setThemeMode(_selectedMode);
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppTheme.primary : AppTheme.lightPrimary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark 
                      ? (isSelected ? Theme.of(context).cardTheme.color?.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.3))
                      : (isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? activeColor : (isDark ? Colors.white.withValues(alpha: 0.54) : Colors.black.withValues(alpha: 0.45)),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Detailed Mini App Preview
                      Container(
                        height: 70,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 30,
                                height: 3,
                                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(height: 4),
                                  Container(width: 25, height: 4, decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
                                ],
                              ),
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Container(width: 20, height: 2, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
