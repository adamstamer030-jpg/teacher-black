import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';

class DashboardStats {
  final int studentsCount;
  final int gradesCount;
  final int groupsCount;
  final int examsCount;
  final int reservationsCount;
  final int lateStudentsCount;
  final double paymentsThisMonth;
  final List<Map<String, dynamic>> todaySchedule;

  DashboardStats({
    required this.studentsCount,
    required this.gradesCount,
    required this.groupsCount,
    required this.examsCount,
    required this.reservationsCount,
    required this.lateStudentsCount,
    required this.paymentsThisMonth,
    required this.todaySchedule,
  });
}

class DashboardRepository {
  final _dbProvider = AppDatabase.instance;

  Future<DashboardStats> load() async {
    final db = await _dbProvider.database;

    final students = await db
        .rawQuery('SELECT COUNT(*) c FROM students WHERE is_archived = 0');
    final grades = await db.rawQuery('SELECT COUNT(*) c FROM grades');
    final groups = await db.rawQuery('SELECT COUNT(*) c FROM groups_table');
    final exams = await db.rawQuery('SELECT COUNT(*) c FROM exams');
    final reservations = await db.rawQuery('SELECT COUNT(*) c FROM reservations');

    final monthKey = AppHelpers.monthYearKey(DateTime.now());
    final late = await db.rawQuery('''
      SELECT COUNT(*) c FROM students s
      WHERE s.is_archived = 0 AND s.group_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM payments p
        WHERE p.student_id = s.id AND p.type = 'اشتراك' AND p.month_year = ?
      )
    ''', [monthKey]);

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);
    final monthPayments = await db.rawQuery(
      'SELECT SUM(amount) s FROM payments WHERE date(payment_date) BETWEEN date(?) AND date(?)',
      [from.toIso8601String(), to.toIso8601String()],
    );

    final todayName = _arabicWeekday(now.weekday);
    final todaySchedule = await db.rawQuery('''
      SELECT s.*, g.name as group_name, g.color as group_color
      FROM schedules s
      JOIN groups_table g ON g.id = s.group_id
      WHERE s.day_of_week = ?
      ORDER BY s.start_time ASC
    ''', [todayName]);

    return DashboardStats(
      studentsCount: (students.first['c'] as int?) ?? 0,
      gradesCount: (grades.first['c'] as int?) ?? 0,
      groupsCount: (groups.first['c'] as int?) ?? 0,
      examsCount: (exams.first['c'] as int?) ?? 0,
      reservationsCount: (reservations.first['c'] as int?) ?? 0,
      lateStudentsCount: (late.first['c'] as int?) ?? 0,
      paymentsThisMonth: (monthPayments.first['s'] as num?)?.toDouble() ?? 0,
      todaySchedule: todaySchedule,
    );
  }

  String _arabicWeekday(int weekday) {
    // DateTime.monday == 1 ... DateTime.sunday == 7
    const map = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return map[weekday] ?? '';
  }
}
