import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../student/student_dashboard.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _matricController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown selections
  String? _selectedDepartment;
  String? _selectedFaculty;
  String? _selectedLevel;

  // Toggle states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  // Multi-step form
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void dispose() {
    _fullNameController.dispose();
    _matricController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_agreedToTerms) {
      AppHelpers.showSnackBar(
        context,
        message: 'Please agree to the terms and conditions to continue',
        isError: true,
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .registerStudent(
          fullName: _fullNameController.text.trim(),
          matricNumber: _matricController.text.trim().toUpperCase(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          department: _selectedDepartment!,
          faculty: _selectedFaculty!,
          level: _selectedLevel!,
        );

    if (!mounted) return;

    if (success) {
      AppHelpers.showSnackBar(
        context,
        message: 'Welcome to SmartClearance! 🎉',
        isSuccess: true,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
        (route) => false,
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        AppHelpers.showSnackBar(
          context,
          message: error,
          isError: true,
        );
        ref.read(authProvider.notifier).clearError();
      }
    }
  }

  void _nextStep() {
    // Validate current step before moving forward
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _handleRegister();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Personal info step
        if (_fullNameController.text.trim().isEmpty) {
          AppHelpers.showSnackBar(
            context,
            message: 'Please enter your full name',
            isError: true,
          );
          return false;
        }
        if (Validators.validateFullName(_fullNameController.text) != null) {
          AppHelpers.showSnackBar(
            context,
            message:
                Validators.validateFullName(_fullNameController.text)!,
            isError: true,
          );
          return false;
        }
        if (Validators.validateMatricNumber(_matricController.text) !=
            null) {
          AppHelpers.showSnackBar(
            context,
            message: Validators.validateMatricNumber(
                _matricController.text)!,
            isError: true,
          );
          return false;
        }
        if (Validators.validatePhoneNumber(_phoneController.text) != null) {
          AppHelpers.showSnackBar(
            context,
            message:
                Validators.validatePhoneNumber(_phoneController.text)!,
            isError: true,
          );
          return false;
        }
        return true;

      case 1:
        // Academic info step
        if (_selectedDepartment == null) {
          AppHelpers.showSnackBar(
            context,
            message: 'Please select your department',
            isError: true,
          );
          return false;
        }
        if (_selectedFaculty == null) {
          AppHelpers.showSnackBar(
            context,
            message: 'Please select your faculty',
            isError: true,
          );
          return false;
        }
        if (_selectedLevel == null) {
          AppHelpers.showSnackBar(
            context,
            message: 'Please select your current level',
            isError: true,
          );
          return false;
        }
        return true;

      case 2:
        // Account security step
        if (Validators.validateEmail(_emailController.text) != null) {
          AppHelpers.showSnackBar(
            context,
            message: Validators.validateEmail(_emailController.text)!,
            isError: true,
          );
          return false;
        }
        if (Validators.validatePassword(_passwordController.text) != null) {
          AppHelpers.showSnackBar(
            context,
            message:
                Validators.validatePassword(_passwordController.text)!,
            isError: true,
          );
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          AppHelpers.showSnackBar(
            context,
            message: 'Passwords do not match',
            isError: true,
          );
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            _buildHeader(),

            // ─── Step Indicator ───────────────────────────────────────
            _buildStepIndicator(),

            const SizedBox(height: 8),

            // ─── Form Content ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Step Title
                      Text(
                        _getStepTitle(),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _getStepSubtitle(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      const SizedBox(height: 28),

                      // Step Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          );
                        },
                        child: _buildCurrentStep(),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Bottom Buttons ───────────────────────────────────────
            _buildBottomButtons(authState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkGrey,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.mediumGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? AppColors.primary
                          : AppColors.borderGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Academic Info';
      case 2:
        return 'Secure Account';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Enter your personal details as they appear on your admission letter';
      case 1:
        return 'Select your department and current academic level';
      case 2:
        return 'Create login credentials for your SmartClearance account';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAcademicInfoStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Personal Info ─────────────────────────────────────────────────
  Widget _buildPersonalInfoStep() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppStrings.fullName),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: AppStrings.fullNameHint,
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.lightGrey,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.matricNumber),
        const SizedBox(height: 8),
        TextFormField(
          controller: _matricController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: AppStrings.matricHint,
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: AppColors.lightGrey,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.phoneNumber),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: AppStrings.phoneHint,
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppColors.lightGrey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: Academic Info ─────────────────────────────────────────────────
  Widget _buildAcademicInfoStep() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppStrings.faculty),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedFaculty,
          hint: 'Select your faculty',
          items: AppStrings.faculties,
          icon: Icons.account_balance_outlined,
          onChanged: (value) =>
              setState(() => _selectedFaculty = value),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.department),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedDepartment,
          hint: 'Select your department',
          items: AppStrings.departments,
          icon: Icons.library_books_outlined,
          onChanged: (value) =>
              setState(() => _selectedDepartment = value),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.level),
        const SizedBox(height: 8),
        _buildDropdown(
          value: _selectedLevel,
          hint: 'Select your current level',
          items: AppStrings.levels,
          icon: Icons.stairs_rounded,
          onChanged: (value) =>
              setState(() => _selectedLevel = value),
        ),

        const SizedBox(height: 20),

        // Info card about matric format
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.infoBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.info, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Make sure your department matches what is on your admission letter. '
                  'This cannot be changed after registration.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.info,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Security ──────────────────────────────────────────────────────
  Widget _buildSecurityStep() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppStrings.email),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: AppStrings.emailHint,
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.lightGrey,
              size: 20,
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.password),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Min. 8 characters with letters and numbers',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.lightGrey,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.lightGrey,
                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        _buildLabel(AppStrings.confirmPassword),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.lightGrey,
              size: 20,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.lightGrey,
                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Terms and Conditions
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (value) =>
                    setState(() => _agreedToTerms = value ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.mediumGrey,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'I agree that all information provided is accurate and matches my university records. '),
                    TextSpan(
                      text: 'False information may result in account suspension.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderGrey),
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _currentStep == _totalSteps - 1
                    ? AppStrings.createAccount
                    : AppStrings.next,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGrey,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.lightGrey,
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.lightGrey),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, color: AppColors.lightGrey, size: 20),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
