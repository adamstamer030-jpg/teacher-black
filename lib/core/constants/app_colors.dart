import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية - مطابقة لتصميم الواجهات المرجعية (بنفسجي/إندغو)
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6366F1); // brand.purple
  static const Color primaryDark = Color(0xFF4F46E5); // brand.darkPurple
  static const Color accent = Color(0xFF8B5CF6);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  /// مجموعة ألوان قابلة للاختيار للمجموعات الدراسية والصفوف
  static const List<Color> palette = [
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

  /// ألوان التطبيق القابلة للاختيار من الإعدادات (Seed colors)
  static const Map<String, Color> appSeedColors = {
    'بنفسجي': Color(0xFF6366F1),
    'أزرق': Color(0xFF2563EB),
    'أخضر': Color(0xFF059669),
    'برتقالي': Color(0xFFEA580C),
    'وردي': Color(0xFFDB2777),
    'تركواز': Color(0xFF0D9488),
  };
}
