import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

class AppHelpers {
  AppHelpers._();

  static String nowIso() => DateTime.now().toIso8601String();

  static String todayDateOnly() =>
      intl.DateFormat('yyyy-MM-dd').format(DateTime.now());

  static String formatDate(String isoOrDateOnly) {
    try {
      final date = DateTime.parse(isoOrDateOnly);
      return intl.DateFormat('yyyy/MM/dd').format(date);
    } catch (_) {
      return isoOrDateOnly;
    }
  }

  static String formatMoney(double value) {
    final f = intl.NumberFormat('#,##0', 'en');
    return '${f.format(value)} ج.م';
  }

  static String monthYearKey(DateTime date) =>
      intl.DateFormat('yyyy-MM').format(date);

  static String monthYearLabel(String key) {
    try {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return intl.DateFormat('MMMM yyyy', 'ar').format(date);
    } catch (_) {
      return key;
    }
  }

  /// تحقق بسيط من صحة رقم الهاتف المصري
  static bool isValidEgyptPhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    final regex = RegExp(r'^01[0125][0-9]{8}$');
    return regex.hasMatch(v);
  }

  /// فتح محادثة واتساب مباشرة مع رقم هاتف مصري
  static Future<void> openWhatsApp(String phone, {String message = ''}) async {
    var clean = phone.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '2$clean'; // 20 كود مصر
    } else if (!clean.startsWith('20')) {
      clean = '20$clean';
    }
    final uri = Uri.parse(
        'https://wa.me/$clean${message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static Future<void> callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  static void vibrateSelection() {
    HapticFeedback.selectionClick();
  }
}

/// مولّد كود الطالب الفريد (تسلسلي: 1, 2, 3 ... ولا يتكرر أبداً)
class CodeGenerator {
  /// يُمرَّر أكبر كود رقمي مستخدم حالياً، ويُرجع الكود التالي كنص بدون أصفار بداية
  static String nextCode(int currentMax) => (currentMax + 1).toString();
}
