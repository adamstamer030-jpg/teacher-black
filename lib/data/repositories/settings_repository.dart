import '../../core/db/app_database.dart';

/// مخزن إعدادات بسيط (key-value) فوق جدول settings في SQLite
class SettingsRepository {
  final _dbProvider = AppDatabase.instance;

  Future<String?> get(String key) async {
    final db = await _dbProvider.database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String? value) async {
    final db = await _dbProvider.database;
    await db.execute(
      'INSERT INTO settings(key, value) VALUES(?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value],
    );
  }

  Future<Map<String, String?>> getAll() async {
    final db = await _dbProvider.database;
    final rows = await db.query('settings');
    final map = <String, String?>{};
    for (final r in rows) {
      map[r['key'] as String] = r['value'] as String?;
    }
    return map;
  }

  // ---- مفاتيح ثابتة مستخدمة بالتطبيق ----
  static const String keyThemeMode = 'theme_mode'; // light/dark/system
  static const String keySeedColor = 'seed_color'; // اسم اللون
  static const String keyFontScale = 'font_scale'; // نص رقمي مثل 1.0
  static const String keyTeacherName = 'teacher_name';
  static const String keyTeacherPhone = 'teacher_phone';
  static const String keyCenterName = 'center_name';
  static const String keyCenterLogo = 'center_logo';
  static const String keyPinHash = 'pin_hash';
  static const String keyPinEnabled = 'pin_enabled';
  static const String keyBiometricEnabled = 'biometric_enabled';
}
