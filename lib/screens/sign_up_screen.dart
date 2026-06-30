import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/sign_up_widgets.dart';
import '../widgets/sign_in_widgets.dart'; // For SecurityMessage
import '../widgets/password_strength_widget.dart';
import '../widgets/app_background_wrapper.dart';
import 'terms_and_conditions_screen.dart';
import 'user_details_screen.dart';

import '../services/auth_service.dart';
import '../utils/validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('agree_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _fullNameController.text.trim(),
        );

        if (mounted) {
          // Navigate to MainScreen or show success message and pop
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account_created'.tr()),
              backgroundColor: Colors.green,
            ),
          );
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const UserDetailsScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackgroundWrapper(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallPhone = constraints.maxWidth < 380;
              final pagePadding = isSmallPhone ? 12.0 : 20.0;
              final cardPadding = isSmallPhone ? 18.0 : 28.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: pagePadding,
                    vertical: 16,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.86) ?? 
                             Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SignUpHeader(),
                          SizedBox(height: isSmallPhone ? 22 : 28),
                          CustomTextField(
                            label: 'full_name'.tr(),
                            controller: _fullNameController,
                            hintText: 'enter_full_name_hint'.tr(),
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                            validator: Validators.validateName,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            label: 'email'.tr(),
                            controller: _emailController,
                            hintText: 'enter_email_hint'.tr(),
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            label: 'password'.tr(),
                            controller: _passwordController,
                            hintText: 'enter_password_hint'.tr(),
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            validator: Validators.validatePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Theme.of(context).hintColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _passwordController,
                            builder: (context, value, child) {
                              return PasswordStrengthWidget(password: value.text);
                            },
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            label: 'confirm_password'.tr(),
                            controller: _confirmPasswordController,
                            hintText: 'confirm_password_hint'.tr(),
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            validator: (value) => Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Theme.of(context).hintColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          TermsAndConditions(
                            agreed: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            onTermsPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndConditionsScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmallPhone ? 22 : 28),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                  text: 'sign_up'.tr(),
                                  onPressed: _handleSignUp,
                                  icon: Icons.person_add_outlined,
                                ),
                          const SizedBox(height: 20),
                          SignInLink(
                            onSignIn: () {
                              Navigator.of(context).pop(); // Go back to Sign In
                            },
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            thickness: 1,
                          ),
                          const SizedBox(height: 10),
                          const SecurityMessage(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
