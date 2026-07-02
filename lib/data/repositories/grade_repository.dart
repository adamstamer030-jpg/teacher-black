import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class GradeRepository {
  final _dbProvider = AppDatabase.instance;

  Future<List<Grade>> getAll() async {
    final db = await _dbProvider.database;
    final rows = await db.query('grades', orderBy: 'sort_order ASC, id ASC');
    return rows.map(Grade.fromMap).toList();
  }

  Future<Grade?> getById(int id) async {
    final db = await _dbProvider.database;
    final rows = await db.query('grades', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Grade.fromMap(rows.first);
  }

  Future<int> add(String name) async {
    final db = await _dbProvider.database;
    final maxOrderRows =
        await db.rawQuery('SELECT MAX(sort_order) as m FROM grades');
    final nextOrder = ((maxOrderRows.first['m'] as int?) ?? 0) + 1;
    return db.insert('grades', {
      'name': name,
      'sort_order': nextOrder,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> update(Grade grade) async {
    final db = await _dbProvider.database;
    await db.update('grades', grade.toMap(),
        where: 'id = ?', whereArgs: [grade.id]);
  }

  Future<void> reorder(List<Grade> orderedGrades) async {
    final db = await _dbProvider.database;
    final batch = db.batch();
    for (var i = 0; i < orderedGrades.length; i++) {
      batch.update('grades', {'sort_order': i},
          where: 'id = ?', whereArgs: [orderedGrades[i].id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('grades', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countStudentsInGrade(int gradeId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM students WHERE grade_id = ? AND is_archived = 0',
        [gradeId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> countGroupsInGrade(int gradeId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM groups_table WHERE grade_id = ?', [gradeId]);
    return (rows.first['c'] as int?) ?? 0;
  }
}
