import 'package:flutter/material.dart';

class AppColors {
  // Private constructor so this class cannot be instantiated
  AppColors._();

  // ─── Primary Brand Colors ───────────────────────────────────────────────────
  // Deep green representing education, trust, and Nigerian identity
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryLighter = Color(0xFF43A047);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // ─── Secondary / Accent Colors ──────────────────────────────────────────────
  // Gold accent representing excellence and university prestige
  static const Color accent = Color(0xFFF9A825);
  static const Color accentLight = Color(0xFFFFF8E1);
  static const Color accentDark = Color(0xFFF57F17);

  // ─── Neutral Colors ─────────────────────────────────────────────────────────
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkGrey = Color(0xFF212121);
  static const Color mediumGrey = Color(0xFF616161);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color borderGrey = Color(0xFFE0E0E0);
  static const Color surfaceGrey = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Semantic / Status Colors ───────────────────────────────────────────────
  // Success - payment verified, form approved
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successBorder = Color(0xFFA5D6A7);

  // Warning - pending, under review
  static const Color warning = Color(0xFFF9A825);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color warningBorder = Color(0xFFFFE082);

  // Error - rejected, failed payment
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorBorder = Color(0xFFEF9A9A);

  // Info - submitted, processing
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoBorder = Color(0xFF90CAF9);

  // ─── Role-Based Colors ──────────────────────────────────────────────────────
  // Each user role has a color identity in the app
  static const Color studentRole = Color(0xFF1565C0);       // Blue
  static const Color adviserRole = Color(0xFF6A1B9A);       // Purple
  static const Color ictAdminRole = Color(0xFFE65100);      // Deep Orange
  static const Color hodRole = Color(0xFF1B5E20);           // Deep Green

  // ─── Background Colors ──────────────────────────────────────────────────────
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF5F5F5);

  // ─── Shadow Colors ──────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x29000000);

  // ─── Gradient Definitions ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  static const LinearGradient studentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
  );

  static const LinearGradient adviserGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)],
  );

  static const LinearGradient ictGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF57C00), Color(0xFFE65100)],
  );

  static const LinearGradient hodGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );

  // ─── Status Color Helpers ───────────────────────────────────────────────────
  // Call these with a status string to get the right color automatically

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'cleared':
        return success;
      case 'pending':
      case 'submitted':
      case 'processing':
        return warning;
      case 'rejected':
      case 'failed':
        return error;
      case 'under_review':
      case 'acknowledged':
        return info;
      default:
        return mediumGrey;
    }
  }

  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'verified':
      case 'cleared':
        return successLight;
      case 'pending':
      case 'submitted':
      case 'processing':
        return warningLight;
      case 'rejected':
      case 'failed':
        return errorLight;
      case 'under_review':
      case 'acknowledged':
        return infoLight;
      default:
        return surfaceGrey;
    }
  }

  static LinearGradient getRoleGradient(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return studentGradient;
      case 'adviser':
        return adviserGradient;
      case 'ict_admin':
        return ictGradient;
      case 'hod':
      case 'super_admin':
        return hodGradient;
      default:
        return primaryGradient;
    }
  }
}
