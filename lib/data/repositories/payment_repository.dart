import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../models/models.dart';

class PaymentRepository {
  final _dbProvider = AppDatabase.instance;

  Future<int> add(Payment payment) async {
    final db = await _dbProvider.database;
    final map = payment.toMap();
    map['created_at'] = AppHelpers.nowIso();
    final id = await db.insert('payments', map);
    if (payment.studentExtraFeeId != null) {
      await db.update('student_extra_fees', {'is_paid': 1},
          where: 'id = ?', whereArgs: [payment.studentExtraFeeId]);
    }
    return id;
  }

  Future<void> delete(int id) async {
    final db = await _dbProvider.database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Payment>> getForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('payments',
        where: 'student_id = ?', whereArgs: [studentId], orderBy: 'payment_date DESC, id DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<double> totalPaidForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT SUM(amount) s FROM payments WHERE student_id = ?', [studentId]);
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalRemainingForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT SUM(due_amount - amount) s FROM payments WHERE student_id = ? AND due_amount > amount',
        [studentId]);
    final fromPayments = (rows.first['s'] as num?)?.toDouble() ?? 0;
    final unpaidFees = await db.rawQuery(
        'SELECT SUM(price) s FROM student_extra_fees WHERE student_id = ? AND is_paid = 0',
        [studentId]);
    final fromFees = (unpaidFees.first['s'] as num?)?.toDouble() ?? 0;
    return fromPayments + fromFees;
  }

  Future<String?> lastPaymentDate(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('payments',
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'payment_date DESC',
        limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['payment_date'] as String;
  }

  /// إجمالي المدفوعات خلال فترة (اليوم / الأسبوع / الشهر / السنة)
  Future<double> totalInRange(DateTime from, DateTime to) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
      'SELECT SUM(amount) s FROM payments WHERE date(payment_date) BETWEEN date(?) AND date(?)',
      [from.toIso8601String(), to.toIso8601String()],
    );
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalThisMonth() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    return totalInRange(from, to);
  }

  /// عدد الطلاب الذين لم يدفعوا اشتراك الشهر الحالي (متأخرين في الدفع)
  Future<int> countLateThisMonth() async {
    final db = await _dbProvider.database;
    final monthKey = AppHelpers.monthYearKey(DateTime.now());
    final rows = await db.rawQuery('''
      SELECT COUNT(*) c FROM students s
      WHERE s.is_archived = 0 AND s.group_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM payments p
        WHERE p.student_id = s.id AND p.type = 'اشتراك' AND p.month_year = ?
      )
    ''', [monthKey]);
    return (rows.first['c'] as int?) ?? 0;
  }

  /// قائمة الطلاب المتأخرين في دفع اشتراك الشهر الحالي
  Future<List<Student>> lateStudentsThisMonth() async {
    final db = await _dbProvider.database;
    final monthKey = AppHelpers.monthYearKey(DateTime.now());
    final rows = await db.rawQuery('''
      SELECT s.* FROM students s
      WHERE s.is_archived = 0 AND s.group_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM payments p
        WHERE p.student_id = s.id AND p.type = 'اشتراك' AND p.month_year = ?
      )
    ''', [monthKey]);
    return rows.map(Student.fromMap).toList();
  }

  Future<bool> hasPaidSubscriptionForMonth(int studentId, String monthKey) async {
    final db = await _dbProvider.database;
    final rows = await db.query('payments',
        where: "student_id = ? AND type = 'اشتراك' AND month_year = ?",
        whereArgs: [studentId, monthKey]);
    return rows.isNotEmpty;
  }

  // ---------------- الرسوم الإضافية المخصصة للطالب ----------------

  Future<List<StudentExtraFee>> getStudentExtraFees(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.query('student_extra_fees',
        where: 'student_id = ?', whereArgs: [studentId], orderBy: 'id DESC');
    return rows.map(StudentExtraFee.fromMap).toList();
  }

  Future<int> assignExtraFee(StudentExtraFee fee) async {
    final db = await _dbProvider.database;
    final map = fee.toMap();
    map['created_at'] = AppHelpers.nowIso();
    return db.insert('student_extra_fees', map);
  }

  Future<void> deleteExtraFee(int id) async {
    final db = await _dbProvider.database;
    await db.delete('student_extra_fees', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> sumExtraFeesForStudent(int studentId) async {
    final db = await _dbProvider.database;
    final rows = await db.rawQuery(
        'SELECT SUM(price) s FROM student_extra_fees WHERE student_id = ?', [studentId]);
    return (rows.first['s'] as num?)?.toDouble() ?? 0;
  }
}
