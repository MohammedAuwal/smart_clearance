import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'screens/auth/splash_screen.dart';

// ─── Supabase Credentials ─────────────────────────────────────────────────────
// Replace these with your actual values from supabase.com
// Project -> Settings -> API -> Project URL and anon key
const String _supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

Future<void> main() async {
  // Ensure Flutter engine is ready before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Lock Orientation to Portrait ──────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ─── Set System UI Overlay Style ────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ─── Initialize Firebase ────────────────────────────────────────────────
  await Firebase.initializeApp();

  // ─── Initialize Supabase ────────────────────────────────────────────────
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    // Enable real-time for live notification updates
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // ─── Run App ────────────────────────────────────────────────────────────
  runApp(
    // ProviderScope wraps the entire app so Riverpod works everywhere
    const ProviderScope(
      child: SmartClearanceApp(),
    ),
  );
}

// ─── Root App Widget ──────────────────────────────────────────────────────────
class SmartClearanceApp extends StatelessWidget {
  const SmartClearanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ─── App Identity ─────────────────────────────────────────────────
      title: 'SmartClearance',
      debugShowCheckedModeBanner: false,

      // ─── Theme ───────────────────────────────────────────────────────
      theme: _buildAppTheme(),

      // ─── Entry Point ──────────────────────────────────────────────────
      // SplashScreen decides where to go based on auth state
      home: const SplashScreen(),
    );
  }

  // ─── App Theme Builder ────────────────────────────────────────────────────
  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardBackground,
        background: AppColors.scaffoldBackground,
        error: AppColors.error,
      ),

      // ─── Scaffold ───────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.scaffoldBackground,

      // ─── Font Family ────────────────────────────────────────────────
      fontFamily: 'Poppins',

      // ─── AppBar Theme ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkGrey,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkGrey,
          size: 22,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ─── Elevated Button Theme ───────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── Outlined Button Theme ───────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text Button Theme ───────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input Decoration Theme ──────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.mediumGrey,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppColors.lightGrey,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.error,
        ),
      ),

      // ─── Card Theme ──────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.borderGrey,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Bottom Navigation Bar Theme ─────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightGrey,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ─── Chip Theme ──────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceGrey,
        selectedColor: AppColors.primarySurface,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ─── Divider Theme ───────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderGrey,
        thickness: 1,
        space: 1,
      ),

      // ─── Text Theme ──────────────────────────────────────────────────
      textTheme: const TextTheme(
        // Large titles
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGrey,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGrey,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
          height: 1.4,
        ),
        // Section titles
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGrey,
        ),
        // Body text
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.darkGrey,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.mediumGrey,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.lightGrey,
          height: 1.5,
        ),
        // Labels
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.mediumGrey,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.lightGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
