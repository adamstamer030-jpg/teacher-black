import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class StudentRepository {
  final _dbProvider = AppDatabase.instance;

  /// توليد كود فريد تلقائي للطالب (تسلسلي ولا يتكرر)
  Future<String> generateNextCode() async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        "SELECT code FROM students WHERE code GLOB '[0-9]*' ORDER BY CAST(code AS INTEGER) DESC LIMIT 1");
    if (rows.isEmpty) return '1';
    final lastCode = int.tryParse(rows.first['code'] as String) ?? 0;
    return CodeGenerator.nextCode(lastCode);
  }

  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'students',
      where: excludeId != null ? 'code = ? AND id != ?' : 'code = ?',
      whereArgs: excludeId != null ? [code, excludeId] : [code],
    );
    return rows.isNotEmpty;
  }

  /// تحقق من عدم تكرار رقم هاتف الطالب داخل التطبيق قبل الحفظ
  Future<bool> isPhoneDuplicate(String phone, {int? excludeId}) async {
    if (phone.trim().isEmpty) return false;
    final db = await _dbProvider.database;
    final rows = await db.query(
      'students',
      where: excludeId != null ? 'phone = ? AND id != ?' : 'phone = ?',
      whereArgs: excludeId != null ? [phone, excludeId] : [phone],
    );
    return rows.isNotEmpty;
  }

  Future<int> add(Student student) async {
    final db = await _dbProvider.database;
    final map = student.toMap();
    map['created_at'] = AppHelpers.nowIso();
    return db.insert('students', map);
  }

  Future<void> update(Student student) async {
    final db = await _dbProvider.database;
    await db.update('students', student.toMap(),
        where: 'id = ?', whereArgs: [student.id]);
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _dbProvider.database;
    await db.update('students', {'is_archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setStatus(int id, String status) async {
    final db = await _dbProvider.database;
    await db.update('students', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> transfer(int id, {int? newGroupId, int? newGradeId}) async {
    final db = await _dbProvider.database;
    final map = <String, dynamic>{};
    if (newGroupId != null) map['group_id'] = newGroupId;
    if (newGradeId != null) map['grade_id'] = newGradeId;
    if (map.isEmpty) return;
    await db.update('students', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<Student?> getById(int id) async {
    final db = await _dbProvider.database;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }

  Future<List<Student>> getByGroup(int groupId, {bool includeArchived = false}) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'students',
      where: includeArchived ? 'group_id = ?' : 'group_id = ? AND is_archived = 0',
      whereArgs: [groupId],
    );
    return rows.map(Student.fromMap).toList();
  }

  /// جلب الطلاب مع فلترة/بحث/ترتيب
  Future<List<Student>> query({
    String? search,
    int? groupId,
    int? gradeId,
    String? status,
    bool includeArchived = false,
    String sort = 'تاريخ الاشتراك (الأقدم أولاً)',
  }) async {
    final db = await _dbProvider.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (!includeArchived) {
      where.add('is_archived = 0');
    }
    if (groupId != null) {
      where.add('group_id = ?');
      args.add(groupId);
    }
    if (gradeId != null) {
      where.add('grade_id = ?');
      args.add(gradeId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      where.add(
          '(name LIKE ? OR code LIKE ? OR phone LIKE ? OR parent_phone LIKE ?)');
      args.addAll([s, s, s, s]);
    }

    String orderBy;
    switch (sort) {
      case 'الاسم':
        orderBy = 'name ASC';
        break;
      case 'الكود':
        orderBy = 'CAST(code AS INTEGER) ASC';
        break;
      case 'آخر عملية دفع':
        orderBy = 'id DESC'; // تقريبي، يُحسب فعلياً عبر آخر دفعة بمستوى أعلى
        break;
      case 'ترتيب يدوي':
        orderBy = 'sort_order ASC';
        break;
      default:
        orderBy = 'subscription_date ASC';
    }

    final rows = await db.query(
      'students',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
    );
    return rows.map(Student.fromMap).toList();
  }

  Future<void> reorderManually(List<Student> students) async {
    final db = await _dbProvider.database;
    final batch = db.batch();
    for (var i = 0; i < students.length; i++) {
      batch.update('students', {'sort_order': i},
          where: 'id = ?', whereArgs: [students[i].id]);
    }
    await batch.commit(noResult: true);
  }

  Future<int> totalActiveStudents() async {
    final db = await _dbProvider.database;
    final rows = await db
        .rawQuery('SELECT COUNT(*) as c FROM students WHERE is_archived = 0');
    return (rows.first['c'] as int?) ?? 0;
  }

  // ---------------- ملاحظات الطالب ----------------

  Future<List<StudentNote>> getNotes(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('student_notes',
        where: 'student_id = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return rows.map(StudentNote.fromMap).toList();
  }

  Future<int> addNote(int studentId, String text) async {
    final db = await _dbProvider.database;
    return db.insert('student_notes', {
      'student_id': studentId,
      'text': text,
      'date': AppHelpers.todayDateOnly(),
      'created_at': AppHelpers.nowIso(),
    });
  }

  Future<void> updateNote(int id, String text) async {
    final db = await _dbProvider.database;
    await db.update('student_notes', {'text': text},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteNote(int id) async {
    final db = await _dbProvider.database;
    await db.delete('student_notes', where: 'id = ?', whereArgs: [id]);
  }
}
