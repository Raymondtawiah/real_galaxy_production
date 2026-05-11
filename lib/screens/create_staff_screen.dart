import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:real_galaxy/models/role.dart';
import 'package:real_galaxy/models/user.dart';
import 'package:real_galaxy/services/firebase_service.dart';
import 'package:real_galaxy/components/owner_app_bar.dart';
import 'package:real_galaxy/components/owner_header.dart';
import 'package:real_galaxy/components/enhanced_form_field.dart';
import 'package:real_galaxy/components/enhanced_button.dart';
import 'package:real_galaxy/services/user_permissions_service.dart';

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Role? _selectedRole;
  bool _obscurePassword = true;
  Role _currentRole = Role.parent;

  final FirebaseService _db = FirebaseService();
  final List<Role> _allowedRoles = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final auth = fb.FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      final profile = await _db.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          _currentRole = profile.role;
        });
        _loadAllowedRoles();
      }
    }
  }

  void _loadAllowedRoles() {
    _allowedRoles.clear();
    switch (_currentRole) {
      case Role.owner:
        _allowedRoles.addAll([
          Role.owner,
          Role.director,
          Role.admin,
          Role.coach,
        ]);
        break;
      case Role.director:
        _allowedRoles.addAll([Role.admin, Role.coach]);
        break;
      case Role.admin:
        _allowedRoles.addAll([Role.coach]);
        break;
      default:
        break;
    }
    if (_allowedRoles.isNotEmpty) {
      _selectedRole = _allowedRoles.first;
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      setState(() => _errorMessage = 'Please select a role');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final auth = fb.FirebaseAuth.instance;
      final creator = auth.currentUser;

      final credential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      if (credential.user != null) {
        final newUser = User(
          id: credential.user!.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim().toLowerCase(),
          password: '',
          role: _selectedRole!,
          mustChangePassword: _selectedRole == Role.admin,
          isActive: true,
          createdBy: creator?.uid ?? '',
          phoneNumber: _phoneNumberController.text.trim().isEmpty
              ? null
              : _phoneNumberController.text.trim(),
        );

        await _db.setUserProfile(credential.user!.uid, newUser);

        // Grant full permissions if creating an owner
        if (_selectedRole == Role.owner) {
          final permissionsService = UserPermissionsService();
          await permissionsService.setOwnerPermissions(credential.user!.uid);
        }

        await auth.signOut();

        if (mounted) {
          setState(() {
            _successMessage =
                '${_selectedRole!.displayName} created! They must change password on first login.';
          });
          _nameController.clear();
          _emailController.clear();
          _phoneNumberController.clear();
          _passwordController.clear();
        }
      }
    } on fb.FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'email-already-in-use') {
        msg = 'Email already registered.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address.';
      } else {
        msg = 'Authentication failed: ${e.message}';
      }

      if (mounted) {
        setState(() => _errorMessage = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Failed to create staff: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _currentRole == Role.owner;

    return Scaffold(
      backgroundColor: isOwner
          ? const Color(0xFFF5F5F5)
          : AppTheme.backgroundColor,
      appBar: OwnerAppBar(
        title: 'Create Staff',
        role: _currentRole,
        showLogo: true,
        showBadge: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OwnerHeader(
                  title: 'Create Staff Account',
                  subtitle: 'Creating as: ${_currentRole.displayName}',
                  badgeText: isOwner
                      ? 'Full Access • Premium Features'
                      : 'Limited Access',
                  showLogo: true,
                  showBadge: true,
                  role: _currentRole,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),

                EnhancedFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Enter staff member\'s full name',
                  prefixIcon: Icons.person,
                  role: _currentRole,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter full name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                EnhancedFormField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter email address',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  role: _currentRole,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                EnhancedFormField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter temporary password',
                  prefixIcon: Icons.lock,
                  obscureText: _obscurePassword,
                  role: _currentRole,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                EnhancedFormField(
                  controller: _phoneNumberController,
                  label: 'Phone Number (Optional)',
                  hintText: 'Enter phone number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  role: _currentRole,
                ),
                const SizedBox(height: 24),

                // Role Selection
                if (_allowedRoles.isNotEmpty) ...[
                  Text(
                    'Assign Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Role>(
                        value: _selectedRole,
                        hint: const Text('Select a role'),
                        isExpanded: true,
                        items: _allowedRoles.map((role) {
                          return DropdownMenuItem<Role>(
                            value: role,
                            child: Row(
                              children: [
                                Icon(
                                  _getRoleIcon(role),
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  role.displayName,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (Role? value) {
                          setState(() => _selectedRole = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: EnhancedButton(
                    text: 'Create Staff',
                    onPressed: _isLoading ? null : _handleCreate,
                    isLoading: _isLoading,
                    role: _currentRole,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(Role role) {
    switch (role) {
      case Role.owner:
        return Icons.star;
      case Role.director:
        return Icons.business;
      case Role.admin:
        return Icons.admin_panel_settings;
      case Role.coach:
        return Icons.sports_soccer;
      case Role.parent:
        return Icons.family_restroom;
    }
  }
}
