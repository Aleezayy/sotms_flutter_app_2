import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background_wrapper.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'terms_conditions'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '''1. Introduction\nWelcome to Smart Oil Transport Monitoring System (SOTMS). By using our application, you agree to these terms.\n\n2. User Accounts\nTo use the system, you must create an account. You are responsible for maintaining the confidentiality of your account credentials.\n\n3. Data Privacy\nWe collect and process personal and sensor data to provide our services. Your data will be handled securely and according to our Privacy Policy.\n\n4. Acceptable Use\nYou agree not to misuse the system, including but not limited to unauthorized access, tampering with sensor data, or using the system for unlawful activities.\n\n5. Liability\nWe are not liable for any direct, indirect, incidental, or consequential damages arising from the use of our services.\n\n6. Changes to Terms\nWe reserve the right to modify these terms at any time. Your continued use of the system constitutes acceptance of the updated terms.''',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
