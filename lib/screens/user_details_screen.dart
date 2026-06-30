import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/app_background_wrapper.dart';
import '../utils/validators.dart';
import 'main_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _companyNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteSetup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _authService.updateUserProfile(
            uid: user.uid,
            name: user.displayName ?? '',
            companyName: _companyNameController.text.trim(),
            role: _roleController.text.trim(),
          );

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          throw 'No user is currently signed in.';
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
              return Center(
                child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 12 : 20,
                vertical: 16,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: EdgeInsets.all(isSmallPhone ? 18 : 28),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.86) ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Complete Setup',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please provide your company details to continue.',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Company Name',
                        controller: _companyNameController,
                        hintText: 'Enter company name',
                        prefixIcon: Icons.business,
                        validator: (value) => value!.isEmpty ? 'Company Name is required' : null,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'User Role',
                          labelStyle: TextStyle(color: Theme.of(context).hintColor),
                          prefixIcon: Icon(Icons.badge_outlined, color: Theme.of(context).hintColor),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        dropdownColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        value: _roleController.text.isEmpty ? null : _roleController.text,
                        items: ['Manager', 'Owner', 'Team'].map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _roleController.text = newValue ?? '';
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Role is required' : null,
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: 'Complete Setup',
                              onPressed: _handleCompleteSetup,
                              icon: Icons.check_circle_outline,
                            ),
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
