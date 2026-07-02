import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/app_database.dart';

/// خدمة التصدير/الاستيراد والنسخ الاحتياطي
/// JSON يُستخدم للنسخ الاحتياطي الكامل لأنه يحافظ على العلاقات بين الجداول.
/// CSV يُستخدم لتصدير جدول بمفرده ليُفتح في برنامج Excel.
class BackupService {
  static const List<String> _tables = [
    'grades',
    'groups_table',
    'schedules',
    'extra_fees',
    'students',
    'student_notes',
    'attendance',
    'exams',
    'exam_results',
    'attachments',
    'student_extra_fees',
    'payments',
    'reservations',
    'notes',
    'settings',
  ];

  /// تصدير قاعدة البيانات بالكامل إلى ملف JSON واحد ومشاركته
  static Future<File> exportFullJsonBackup() async {
    final db = await AppDatabase.instance.database;
    final Map<String, dynamic> data = {};
    for (final table in _tables) {
      data[table] = await db.query(table);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  static Future<void> shareFullJsonBackup() async {
    final file = await exportFullJsonBackup();
    await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية كاملة لبيانات التطبيق');
  }

  /// استعادة نسخة احتياطية JSON: يمسح الجداول الحالية ثم يعيد إدخال البيانات
  static Future<void> restoreFromJson(File file) async {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);
    final db = await AppDatabase.instance.database;

    await db.transaction((txn) async {
      // الحذف بترتيب عكسي لتفادي مشاكل المفاتيح الأجنبية
      for (final table in _tables.reversed) {
        await txn.delete(table);
      }
      for (final table in _tables) {
        final rows = (data[table] as List?) ?? [];
        for (final row in rows) {
          await txn.insert(table, Map<String, dynamic>.from(row));
        }
      }
    });
  }

  /// تصدير جدول واحد بصيغة CSV (لفتحه في Excel)
  static Future<void> exportTableAsCsv(String table) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(table);
    if (rows.isEmpty) return;

    final headers = rows.first.keys.toList();
    final csvData = [
      headers,
      ...rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()),
    ];
    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$table.csv');
    await file.writeAsString(csvString, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير جدول $table');
  }

  /// تصدير كل الجداول إلى ملف JSON منفصل (لكل جدول) - تصدير JSON عام
  static Future<void> exportAllAsJson() async {
    await shareFullJsonBackup();
  }
}
