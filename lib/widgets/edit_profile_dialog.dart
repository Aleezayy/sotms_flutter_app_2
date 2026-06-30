import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileDialog({super.key, required this.userData});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _roleController;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _companyController = TextEditingController(text: widget.userData['companyName']);
    _roleController = TextEditingController(text: widget.userData['role']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserProfile(
        uid: currentUser!.uid,
        name: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        role: _roleController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Edit Profile', style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.w800)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _companyController,
              label: 'Company',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _roleController,
              label: 'Role',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(72, 44),
          ),
          child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: TextButton.styleFrom(
            minimumSize: const Size(72, 44),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.primaryColor),
                )
              : Text('Save', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      style: TextStyle(color: enabled ? theme.textTheme.bodyLarge?.color : theme.hintColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.hintColor),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.14))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
      ),
    );
  }
}
