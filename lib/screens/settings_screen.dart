import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/app_background_wrapper.dart';
import 'critical_alerts_screen.dart';
import 'sign_in_screen.dart';
import '../main.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();

  void _showEditProfileDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProfileDialog(userData: userData),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('sign_out'.tr(), style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.w800)),
        content: Text(
          'sign_out_confirmation'.tr(),
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(72, 44)),
            child: Text('cancel'.tr(), style: TextStyle(color: theme.hintColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(minimumSize: const Size(88, 44)),
            child: Text('sign_out'.tr(), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('language'.tr(), style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
              trailing: context.locale == const Locale('en')
                  ? Icon(Icons.check, color: theme.primaryColor)
                  : null,
            ),
            ListTile(
              title: Text('اردو', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
              onTap: () {
                context.setLocale(const Locale('ur'));
                Navigator.pop(context);
              },
              trailing: context.locale == const Locale('ur')
                  ? Icon(Icons.check, color: theme.primaryColor)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Error fetching profile'));
            
            // Defaults
            String name = currentUser!.displayName ?? 'User';
            String email = currentUser!.email ?? '';
            String company = 'Not Set';
            String role = 'Not Set';
            Map<String, dynamic> userData = {};

            if (snapshot.hasData && snapshot.data!.exists) {
                userData = snapshot.data!.data() as Map<String, dynamic>;
                name = userData['name'] ?? name;
                email = userData['email'] ?? email;
                company = userData['companyName'] ?? company;
                role = userData['role'] ?? role;
            }

            // prepare data map for dialog
            userData['name'] = name;
            userData['email'] = email;
            userData['companyName'] = company;
            userData['role'] = role;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: Column(
            children: [
              ProfileInfoCard(
                name: name,
                email: email,
                company: company,
                role: role,
                onEdit: () => _showEditProfileDialog(userData),
              ),
              const SizedBox(height: 24),
              
              SettingsSection(
                title: 'notifications'.tr(),
                children: [
                  SettingsTile(
                    icon: Icons.notifications_none,
                    title: 'push_notifications'.tr(),
                    subtitle: 'push_notifications_subtitle'.tr(),
                    trailing: Switch(
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                   SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'critical_alerts'.tr(),
                    subtitle: 'critical_alerts_subtitle'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CriticalAlertsScreen()),
                      );
                    },
                  ),
                ],
              ),

              SettingsSection(
                title: 'preferences'.tr(),
                children: [
                  SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'dark_mode'.tr(),
                    subtitle: 'dark_mode_subtitle'.tr(),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeThumbColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  SettingsTile(
                    icon: Icons.language,
                    title: 'language'.tr(),
                    subtitle: context.locale == const Locale('en') ? 'English' : 'اردو',
                    onTap: _showLanguageDialog,
                  ),
                ],
              ),

              SettingsSection(
                title: 'security'.tr(),
                children: [
                  SettingsTile(
                    icon: Icons.security,
                    title: 'change_password'.tr(),
                    subtitle: 'change_password_subtitle'.tr(),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmationDialog(context),
                  icon: const Icon(Icons.logout),
                  label: Text('sign_out'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Text(
                '${'version'.tr()} 1.0.0',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  ),
),
);
}
}
