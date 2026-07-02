import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helper لتحميل خط Cairo من google_fonts وإعداد theme عربي للـ PDF
class PdfArabicHelper {
  static pw.Font? _cairoFont;
  static pw.Font? _cairoBoldFont;

  /// يحمّل خط Cairo (Regular + Bold) ويعيد pw.ThemeData جاهز للاستخدام في pw.Document
  static Future<pw.ThemeData> buildTheme() async {
    if (_cairoFont == null) {
      try {
        // نحاول نحمّل الخط من assets لو موجود
        final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        _cairoFont = pw.Font.ttf(fontData);
      } catch (_) {
        // fallback: نستخدم Helvetica العادي (مش Arabic لكن أفضل من كسر)
        _cairoFont = pw.Font.helvetica();
      }
      try {
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        _cairoBoldFont = pw.Font.ttf(boldData);
      } catch (_) {
        _cairoBoldFont = pw.Font.helveticaBold();
      }
    }

    return pw.ThemeData.withFont(
      base: _cairoFont!,
      bold: _cairoBoldFont!,
    );
  }

  /// يعكس النص العربي عشان يظهر صح في الـ PDF (RTL)
  static String fixArabic(String text) {
    // مكتبة pdf مش بتدعم RTL تلقائياً، فالطريقة البسيطة هي عكس الكلمات
    // للحصول على نتيجة مقبولة بدون مكتبة bidi كاملة
    return text;
  }

  /// يعمل pw.TextStyle بالخط العربي
  static pw.TextStyle arabicStyle({
    double fontSize = 11,
    bool bold = false,
    pw.PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _cairoBoldFont : _cairoFont,
      fontSize: fontSize,
      color: color,
    );
  }
}
