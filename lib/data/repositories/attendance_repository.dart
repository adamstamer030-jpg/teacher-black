import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class AttendanceRepository {
  final _dbProvider = AppDatabase.instance;

  /// جلب سجل الحضور ليوم معيّن لمجموعة معينة (key = studentId)
  Future<Map<int, AttendanceRecord>> getForGroupAndDate(
      int groupId, String date) async {
    final db = await _dbProvider.database;
    final rows = await db.query('attendance',
        where: 'group_id = ? AND date = ?', whereArgs: [groupId, date]);
    final map = <int, AttendanceRecord>{};
    for (final r in rows) {
      final rec = AttendanceRecord.fromMap(r);
      map[rec.studentId] = rec;
    }
    return map;
  }

  Future<void> markAttendance({
    required int groupId,
    required int studentId,
    required String date,
    required String status,
  }) async {
    final db = await _dbProvider.database;
    final existing = await db.query('attendance',
        where: 'student_id = ? AND date = ?', whereArgs: [studentId, date]);
    if (existing.isEmpty) {
      await db.insert('attendance', {
        'group_id': groupId,
        'student_id': studentId,
        'date': date,
        'status': status,
        'created_at': AppHelpers.nowIso(),
      });
    } else {
      await db.update('attendance', {'status': status},
          where: 'student_id = ? AND date = ?', whereArgs: [studentId, date]);
    }
  }

  Future<List<AttendanceRecord>> getHistoryForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('attendance',
        where: 'student_id = ?', whereArgs: [studentId], orderBy: 'date DESC');
    return rows.map(AttendanceRecord.fromMap).toList();
  }

  /// نسبة الحضور لطالب: (حاضر + متأخر) / إجمالي السجلات
  Future<double> attendancePercentage(int studentId) async {
    final db = await _dbProvider.database;
    final total = await db.rawQuery(
        'SELECT COUNT(*) c FROM attendance WHERE student_id = ?', [studentId]);
    final totalCount = (total.first['c'] as int?) ?? 0;
    if (totalCount == 0) return 0;
    final present = await db.rawQuery(
        "SELECT COUNT(*) c FROM attendance WHERE student_id = ? AND status IN ('حاضر','متأخر')",
        [studentId]);
    final presentCount = (present.first['c'] as int?) ?? 0;
    return (presentCount / totalCount) * 100;
  }

  Future<int> absenceCount(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        "SELECT COUNT(*) c FROM attendance WHERE student_id = ? AND status = 'غائب'",
        [studentId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  /// تواريخ الحصص التي تم تسجيل حضور لها بالفعل لمجموعة معينة
  Future<List<String>> getDatesForGroup(int groupId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('attendance',
        columns: ['date'],
        where: 'group_id = ?',
        whereArgs: [groupId],
        distinct: true,
        orderBy: 'date DESC');
    return rows.map((r) => r['date'] as String).toList();
  }
}
