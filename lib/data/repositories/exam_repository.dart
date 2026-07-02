import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class ExamRepository {
  final _dbProvider = AppDatabase.instance;

  Future<List<Exam>> getByGroup(int groupId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('exams',
        where: 'group_id = ?', whereArgs: [groupId], orderBy: 'date DESC');
    return rows.map(Exam.fromMap).toList();
  }

  Future<Exam?> getById(int id) async {
    final db = await _dbProvider.database;
    final rows = await db.query('exams', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Exam.fromMap(rows.first);
  }

  Future<int> add(Exam exam) async {
    final db = await _dbProvider.database;
    return db.insert('exams', {
      'group_id': exam.groupId,
      'name': exam.name,
      'date': exam.date,
      'curriculum': exam.curriculum,
      'max_score': exam.maxScore,
      'notes': exam.notes,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> update(Exam exam) async {
    final db = await _dbProvider.database;
    await db.update('exams', exam.toMap(), where: 'id = ?', whereArgs: [exam.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- النتائج ----------------

  Future<ExamResult?> getResult(int examId, int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('exam_results',
        where: 'exam_id = ? AND student_id = ?', whereArgs: [examId, studentId]);
    if (rows.isEmpty) return null;
    return ExamResult.fromMap(rows.first);
  }

  Future<Map<int, ExamResult>> getResultsForExam(int examId) async {
    final db = await _dbProvider.database;
    final rows =
        await db.query('exam_results', where: 'exam_id = ?', whereArgs: [examId]);
    final map = <int, ExamResult>{};
    for (final r in rows) {
      final res = ExamResult.fromMap(r);
      map[res.studentId] = res;
    }
    return map;
  }

  Future<int> saveResult({
    required int examId,
    required int studentId,
    double? score,
    String? notes,
  }) async {
    final db = await _dbProvider.database;
    final existing = await getResult(examId, studentId);
    if (existing == null) {
      return db.insert('exam_results', {
        'exam_id': examId,
        'student_id': studentId,
        'score': score,
        'notes': notes,
        'created_at': AppHelpers.nowIso(),
      });
    } else {
      await db.update(
        'exam_results',
        {'score': score, 'notes': notes},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
  }

  Future<List<ExamResult>> getResultsForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('exam_results',
        where: 'student_id = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return rows.map(ExamResult.fromMap).toList();
  }

  Future<Map<String, double>> studentScoreStats(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT AVG(score) avg_s, MAX(score) max_s, MIN(score) min_s FROM exam_results WHERE student_id = ? AND score IS NOT NULL',
        [studentId]);
    if (rows.isEmpty) return {'avg': 0, 'max': 0, 'min': 0};
    final row = rows.first;
    return {
      'avg': (row['avg_s'] as num?)?.toDouble() ?? 0,
      'max': (row['max_s'] as num?)?.toDouble() ?? 0,
      'min': (row['min_s'] as num?)?.toDouble() ?? 0,
    };
  }

  // ---------------- مرفقات صور الامتحان ----------------

  Future<List<ExamAttachment>> getAttachments(int examResultId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('attachments',
        where: 'exam_result_id = ?', whereArgs: [examResultId]);
    return rows.map(ExamAttachment.fromMap).toList();
  }

  Future<int> addAttachment(int examResultId, String filePath) async {
    final db = await _dbProvider.database;
    return db.insert('attachments', {
      'exam_result_id': examResultId,
      'file_path': filePath,
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> deleteAttachment(int id) async {
    final db = await _dbProvider.database;
    await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }
}
