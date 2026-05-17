import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../adviser/adviser_dashboard.dart';
import '../hod/hod_dashboard.dart';
import '../ict_admin/ict_dashboard.dart';

class StaffRegisterScreen extends ConsumerStatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  ConsumerState<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends ConsumerState<StaffRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _inviteCode = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _inviteCode.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final token = _inviteCode.text.trim();

    // 1) Validate invite
    final inviteRes = await SupabaseService().getStaffInviteByToken(token);

    if (!mounted) return;

    if (!inviteRes.success || inviteRes.data == null) {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(context, message: inviteRes.error ?? 'Invalid invite code.', isError: true);
      return;
    }

    final invite = inviteRes.data!;
    final isUsed = (invite['is_used'] as bool?) ?? false;
    final role = invite['role']?.toString() ?? '';
    final dept = invite['department']?.toString() ?? '';
    final assignedLevel = invite['assigned_level']?.toString(); // may be null
    final expiresRaw = invite['expires_at']?.toString();
    final expiresAt = expiresRaw == null ? null : DateTime.tryParse(expiresRaw);

    if (isUsed) {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(context, message: 'This invite code has already been used.', isError: true);
      return;
    }

    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(context, message: 'This invite code has expired.', isError: true);
      return;
    }

    if (role.isEmpty || dept.isEmpty) {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(context, message: 'Invite is missing role/department.', isError: true);
      return;
    }

    // 2) Create Firebase account
    final authRes = await FirebaseAuthService().registerWithEmailAndPassword(
      email: _email.text.trim(),
      password: _password.text,
    );

    if (!mounted) return;

    if (!authRes.success || authRes.user == null) {
      setState(() => _loading = false);
      AppHelpers.showSnackBar(context, message: authRes.message, isError: true);
      return;
    }

    final firebaseUser = authRes.user!;
    await FirebaseAuthService().updateDisplayName(_fullName.text.trim());

    // 3) Create Supabase user profile (matric_number required => generate STAFF code)
    final staffMatric = 'STAFF-${firebaseUser.uid.substring(0, 8).toUpperCase()}';

    final profile = UserModel(
      id: firebaseUser.uid,
      firebaseUid: firebaseUser.uid,
      fullName: _fullName.text.trim(),
      matricNumber: staffMatric,
      email: _email.text.trim().toLowerCase(),
      phoneNumber: _phone.text.trim(),
      department: dept,
      faculty: 'N/A',
      currentLevel: assignedLevel ?? 'N/A',
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final createRes = await SupabaseService().createUserProfile(profile);

    if (!mounted) return;

    if (!createRes.success) {
      setState(() => _loading = false);
      // rollback firebase user to avoid half-created accounts
      await FirebaseAuthService().deleteAccount();
      AppHelpers.showSnackBar(context, message: createRes.error ?? 'Failed to create profile.', isError: true);
      return;
    }

    // 4) Mark invite used
    await SupabaseService().markStaffInviteUsed(token: token, usedBy: firebaseUser.uid);

    setState(() => _loading = false);

    // 5) Route by role
    Widget dest;
    switch (role) {
      case 'adviser':
        dest = const AdviserDashboard();
        break;
      case 'ict_admin':
        dest = const IctDashboard();
        break;
      case 'hod':
      case 'super_admin':
        dest = const HodDashboard();
        break;
      default:
        dest = const AdviserDashboard();
    }

    if (!mounted) return;

    AppHelpers.showSnackBar(context, message: 'Staff account created successfully.', isSuccess: true);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Registration')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: const Text(
              'Staff registration requires an Invite Code from the HOD/Department.\n'
              'If you don’t have a code, contact your HOD.',
              style: TextStyle(color: AppColors.darkGrey, height: 1.5, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullName,
                      validator: Validators.validateFullName,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      validator: Validators.validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      validator: Validators.validatePhoneNumber,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _inviteCode,
                      validator: (v) => Validators.validateRequired(v, 'Invite Code'),
                      decoration: const InputDecoration(
                        labelText: 'Invite Code',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      validator: Validators.validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      validator: (v) => Validators.validateConfirmPassword(v, _password.text),
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text('Create Staff Account'),
                    ),
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
