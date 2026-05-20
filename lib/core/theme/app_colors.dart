import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color background = Color(0xFFFFFFF5); // Ivory
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF059669); // Emerald
  static const Color primaryDark = Color(0xFF065F46); // Deep Emerald
  static const Color primaryLight = Color(0xFFECFDF5);

  // Accent Colors
  static const Color accentBlue = Color(0xFF22D3EE); // Water / data
  static const Color accentGreen = Color(0xFF4ADE80); // Active states
  static const Color accentOrange = Color(0xFFFB923C); // Warnings
  static const Color accentPurple = Color(0xFF8B5CF6); // AI features
  static const Color accentRed = Color(0xFFEF4444); // Critical alerts
  static const Color accentGold = Color(0xFFF59E0B); // Biological / recovery

  // Neutral Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0x0F000000); // rgba(0,0,0,0.06)
  static const Color shimmerBase = Color(0xFFF3F4F6);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pnlGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bioGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient healthBlueGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [accentBlue, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [accentPurple, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
