import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// API Configuration
/// - For Flutter Web (Chrome/Edge): http://localhost:5000/api
/// - For Android Emulator: http://10.0.2.2:5000/api
/// - For iOS / Desktop / Physical Device: http://127.0.0.1:5000/api
String get baseUrl {
  if (kIsWeb) {
    return "http://localhost:5000/api";
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return "http://10.0.2.2:5000/api";
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    default:
      return "http://127.0.0.1:5000/api";
  }
}

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:5000/api";
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://10.0.2.2:5000/api";
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return "http://127.0.0.1:5000/api";
    }
  }
}

/// Modern Corporate Color Palette
class AppColors {
  // Primary & Accent Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryColor = primary;
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryDark = Color(0xFF172554); // Midnight Blue
  static const Color secondary = Color(0xFF0D9488); // Modern Teal Accent

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color border = Color(0xFFE2E8F0); // Slate 200

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson Red
}

/// Layout Dimensions & Constants
class AppDimensions {
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 999.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
}
