import 'package:flutter/material.dart';

/// Exact color system per §11:
/// Main app palette:
/// - Cream: #FFFDF5
/// - Dark Olive Green: #556B2F
/// - Warm Golden: #E8A94B
/// - Deep Charcoal: #2E2E2E
///
/// Confidence module exception ONLY:
/// - Deep Mauve: #674D66
/// - Soft Pink Blush: #EBD6DC
class AppColors {
  // Main app palette
  static const Color cream = Color(0xFFFFFDF5);
  static const Color darkOlive = Color(0xFF556B2F);
  static const Color warmGolden = Color(0xFFE8A94B);
  static const Color deepCharcoal = Color(0xFF2E2E2E);

  // Confidence module palette (ONLY for Confidence screens)
  static const Color deepMauve = Color(0xFF674D66);
  static const Color pinkBlush = Color(0xFFEBD6DC);

  // Surface tints derived from main palette
  static const Color creamSurface = Color(0xFFF9F6EB);
  static const Color borderCharcoal = Color(0x1F2E2E2E);
  static const Color mutedCharcoal = Color(0x992E2E2E);
}
