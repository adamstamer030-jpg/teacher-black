import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class GroupRepository {
  final _dbProvider = AppDatabase.instance;

  Future<List<StudyGroup>> getAll() async {
    final db = await _dbProvider.database;
    final rows =
        await db.query('groups_table', orderBy: 'sort_order ASC, id ASC');
    return rows.map(StudyGroup.fromMap).toList();
  }

  Future<List<StudyGroup>> getByGrade(int gradeId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('groups_table',
        where: 'grade_id = ?', whereArgs: [gradeId], orderBy: 'id ASC');
    return rows.map(StudyGroup.fromMap).toList();
  }

  Future<StudyGroup?> getById(int id) async {
    final db = await _dbProvider.database;
    final rows =
        await db.query('groups_table', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return StudyGroup.fromMap(rows.first);
  }

  Future<int> add(StudyGroup group) async {
    final db = await _dbProvider.database;
    return db.insert('groups_table', {
      'grade_id': group.gradeId,
      'name': group.name,
      'color': group.color,
      'notes': group.notes,
      'monthly_fee': group.monthlyFee,
      'sort_order': 0,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> update(StudyGroup group) async {
    final db = await _dbProvider.database;
    await db.update('groups_table', group.toMap(),
        where: 'id = ?', whereArgs: [group.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('groups_table', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countStudents(int groupId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM students WHERE group_id = ? AND is_archived = 0',
        [groupId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  // ---------------- المواعيد ----------------

  Future<List<GroupSchedule>> getSchedules(int groupId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('schedules',
        where: 'group_id = ?', whereArgs: [groupId], orderBy: 'id ASC');
    return rows.map(GroupSchedule.fromMap).toList();
  }

  Future<int> addSchedule(GroupSchedule schedule) async {
    final db = await _dbProvider.database;
    return db.insert('schedules', {
      'group_id': schedule.groupId,
      'day_of_week': schedule.dayOfWeek,
      'start_time': schedule.startTime,
      'end_time': schedule.endTime,
      'location': schedule.location,
      'notes': schedule.notes,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> deleteSchedule(int id) async {
    final db = await _dbProvider.database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  /// كل مواعيد كل المجموعات (تُستخدم في لوحة التحكم وجدول اليوم)
  Future<List<Map<String, dynamic>>> getAllSchedulesWithGroup() async {
    final db = await _dbProvider.database;
    return db.rawQuery('''
      SELECT s.*, g.name as group_name, g.color as group_color
      FROM schedules s
      JOIN groups_table g ON g.id = s.group_id
      ORDER BY s.start_time ASC
    ''');
  }

  // ---------------- قوالب الرسوم الإضافية ----------------

  Future<List<ExtraFeeTemplate>> getExtraFees(int groupId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('extra_fees',
        where: 'group_id = ?', whereArgs: [groupId], orderBy: 'id ASC');
    return rows.map(ExtraFeeTemplate.fromMap).toList();
  }

  Future<int> addExtraFee(ExtraFeeTemplate fee) async {
    final db = await _dbProvider.database;
    return db.insert('extra_fees', {
      'group_id': fee.groupId,
      'name': fee.name,
      'price': fee.price,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> deleteExtraFee(int id) async {
    final db = await _dbProvider.database;
    await db.delete('extra_fees', where: 'id = ?', whereArgs: [id]);
  }
}
