class Validators {
  Validators._();

  // ─── Email Validator ──────────────────────────────────────────────────────
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+'
      r'@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // ─── Password Validator ───────────────────────────────────────────────────
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return 'Password must contain letters and numbers';
    }

    return null;
  }

  // ─── Confirm Password Validator ───────────────────────────────────────────
  static String? validateConfirmPassword(
      String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ─── Full Name Validator ──────────────────────────────────────────────────
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }

    // Must have at least two words (first and last name)
    final parts = value.trim().split(' ');
    if (parts.length < 2 || parts.any((p) => p.isEmpty)) {
      return 'Please enter your full name (first and last name)';
    }

    // Only letters and spaces allowed
    final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters';
    }

    return null;
  }

  // ─── Matric Number Validator ──────────────────────────────────────────────
  // Nigerian university matric format: U20/CSC/1045 or similar
  static String? validateMatricNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Matric number is required';
    }

    final cleaned = value.trim().toUpperCase();

    // Accept common Nigerian university matric formats
    // e.g. U20/CSC/1045 or CSC/2020/001 or 20/CSC/001
    final matricRegex = RegExp(
      r'^[A-Z0-9]{1,5}/[A-Z]{2,5}/[0-9]{3,5}$',
    );

    if (!matricRegex.hasMatch(cleaned)) {
      return 'Invalid matric format. Example: U20/CSC/1045';
    }

    return null;
  }

  // ─── Phone Number Validator ───────────────────────────────────────────────
  // Nigerian phone numbers: 0801, 0802, 0803, 0805, 0806, 0807, 0808, etc.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');

    // Accept 080XXXXXXXX, 070XXXXXXXX, 090XXXXXXXX, +234XXXXXXXXXX
    final phoneRegex = RegExp(r'^(\+234|0)[7-9][01]\d{8}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid Nigerian phone number (e.g. 08012345678)';
    }

    return null;
  }

  // ─── RRR Number Validator ─────────────────────────────────────────────────
  // Remita Retrieval Reference is a 12-digit number
  static String? validateRrr(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'RRR number is required';
    }

    final cleaned = value.trim().replaceAll(RegExp(r'\s'), '');

    if (cleaned.length != 12) {
      return 'RRR must be exactly 12 digits';
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return 'RRR must contain only numbers';
    }

    return null;
  }

  // ─── Required Field Validator ─────────────────────────────────────────────
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ─── Credit Units Validator ───────────────────────────────────────────────
  static String? validateCreditUnits(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Total credit units is required';
    }

    final units = int.tryParse(value.trim());

    if (units == null) {
      return 'Please enter a valid number';
    }

    if (units < 1) {
      return 'Credit units cannot be less than 1';
    }

    // Nigerian universities typically cap at 24 units per semester
    if (units > 24) {
      return 'Credit units cannot exceed 24 per semester';
    }

    return null;
  }

  // ─── Rejection Reason Validator ───────────────────────────────────────────
  static String? validateRejectionReason(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please provide a reason for rejection';
    }

    if (value.trim().length < 10) {
      return 'Reason must be at least 10 characters';
    }

    if (value.trim().length > 500) {
      return 'Reason must not exceed 500 characters';
    }

    return null;
  }

  // ─── Announcement Title Validator ─────────────────────────────────────────
  static String? validateAnnouncementTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Announcement title is required';
    }

    if (value.trim().length < 5) {
      return 'Title must be at least 5 characters';
    }

    if (value.trim().length > 100) {
      return 'Title must not exceed 100 characters';
    }

    return null;
  }

  // ─── Announcement Body Validator ──────────────────────────────────────────
  static String? validateAnnouncementBody(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Announcement message is required';
    }

    if (value.trim().length < 10) {
      return 'Message must be at least 10 characters';
    }

    if (value.trim().length > 2000) {
      return 'Message must not exceed 2000 characters';
    }

    return null;
  }

  // ─── Dropdown Selection Validator ─────────────────────────────────────────
  static String? validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select a $fieldName';
    }
    return null;
  }
}
