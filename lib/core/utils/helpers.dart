import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class AppHelpers {
  AppHelpers._();

  // ─── Date Formatters ──────────────────────────────────────────────────────

  // Format: 15 Jan 2025
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  // Format: 15 January 2025
  static String formatDateLong(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  // Format: 15/01/2025
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format: 15 Jan 2025, 2:30 PM
  static String formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  // Format: 2:30 PM
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  // ─── Greeting Based on Time of Day ───────────────────────────────────────
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ─── Naira Amount Formatter ───────────────────────────────────────────────
  static String formatNaira(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format without decimal for whole numbers
  static String formatNairaWhole(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // ─── Matric Number Formatter ──────────────────────────────────────────────
  // Ensures consistent uppercase formatting
  static String formatMatricNumber(String matric) {
    return matric.trim().toUpperCase();
  }

  // ─── Phone Number Formatter ───────────────────────────────────────────────
  // Converts +2348012345678 to 08012345678
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'\s'), '');
    if (cleaned.startsWith('+234')) {
      return '0${cleaned.substring(4)}';
    }
    return cleaned;
  }

  // ─── Get Status Display Properties ───────────────────────────────────────
  // Returns a record with color, background, and label for any status string
  static ({Color color, Color background, Color border, String label})
      getStatusProps(String status) {
    return (
      color: AppColors.getStatusColor(status),
      background: AppColors.getStatusBackgroundColor(status),
      border: AppColors.getStatusColor(status).withOpacity(0.3),
      label: _statusLabel(status),
    );
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'verified':
        return 'Verified';
      case 'cleared':
        return 'Cleared';
      case 'pending':
        return 'Pending';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      case 'failed':
        return 'Failed';
      case 'processing':
        return 'Processing';
      case 'acknowledged':
        return 'Acknowledged';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ─── Role Display Name ────────────────────────────────────────────────────
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return 'Student';
      case 'adviser':
        return 'Level Adviser';
      case 'ict_admin':
        return 'ICT Administrator';
      case 'hod':
        return 'Head of Department';
      case 'super_admin':
        return 'Super Administrator';
      default:
        return role;
    }
  }

  // ─── Level Display ────────────────────────────────────────────────────────
  static String getLevelDisplay(String level) {
    // Normalize: "100level" -> "100 Level", "100 Level" stays the same
    final cleaned = level.trim();
    if (cleaned.contains(' ')) return cleaned;
    final digits = RegExp(r'\d+').firstMatch(cleaned)?.group(0) ?? '';
    return '$digits Level';
  }

  // ─── File Size Formatter ──────────────────────────────────────────────────
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // ─── Semester Display ─────────────────────────────────────────────────────
  static String getSemesterDisplay(String semester, String session) {
    return '$semester - $session Session';
  }

  // ─── Truncate Long Text ───────────────────────────────────────────────────
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ─── Get Initials from Name ───────────────────────────────────────────────
  static String getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (fullName.length >= 2) {
      return fullName.substring(0, 2).toUpperCase();
    }
    return fullName.toUpperCase();
  }

  // ─── Show Snackbar ────────────────────────────────────────────────────────
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isSuccess
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppColors.error
            : isSuccess
                ? AppColors.success
                : AppColors.darkGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  // ─── Show Loading Dialog ──────────────────────────────────────────────────
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(width: 20),
                Text(
                  message ?? 'Please wait...',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: AppColors.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hide Loading Dialog ──────────────────────────────────────────────────
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ─── Show Confirmation Dialog ─────────────────────────────────────────────
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.darkGrey,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.mediumGrey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDangerous ? AppColors.error : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ─── Current Semester Helper ──────────────────────────────────────────────
  // Determines whether we are in First or Second semester based on month
  static String getCurrentSemester() {
    final month = DateTime.now().month;
    // Sept to Jan = First Semester
    // Feb to Aug = Second Semester
    if (month >= 9 || month == 1) return 'First Semester';
    return 'Second Semester';
  }

  // ─── Current Session Helper ───────────────────────────────────────────────
  static String getCurrentSession() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Academic year starts in September
    if (month >= 9) {
      return '$year/${year + 1}';
    } else {
      return '${year - 1}/$year';
    }
  }
}
