import 'package:flutter/material.dart';

/// Centralized color palette for Home Vault.
///
/// Expiry status colors follow a traffic-light convention so users
/// instantly understand urgency without reading labels.
abstract class AppColors {
  // Primary — Deep Indigo (trust, organization)
  static const Color primary = Color(0xFF3D52D5);
  static const Color primaryLight = Color(0xFF6B7FE3);
  static const Color primaryDark = Color(0xFF2A3AA0);

  // Secondary — Teal (freshness, life)
  static const Color secondary = Color(0xFF00B4A6);
  static const Color secondaryLight = Color(0xFF4ECDC4);
  static const Color secondaryDark = Color(0xFF007A70);

  // Semantic status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey800 = Color(0xFF1F2937);

  // Surfaces
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Expiry urgency
  static const Color expiryExpired = Color(0xFFEF4444);   // past expiry
  static const Color expirySoon7 = Color(0xFFF97316);     // within 7 days
  static const Color expirySoon30 = Color(0xFFF59E0B);    // within 30 days
  static const Color expiryGood = Color(0xFF22C55E);      // safe
}
