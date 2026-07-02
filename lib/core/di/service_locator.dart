import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/grade_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/student_repository.dart';

/// حاوية بسيطة (Service Locator) تمنح كل التطبيق نسخة واحدة (Singleton)
/// من كل Repository، بدلاً من تمريرها يدوياً عبر كل الشاشات.
class Locator {
  Locator._();
  static final Locator instance = Locator._();

  final GradeRepository gradeRepository = GradeRepository();
  final GroupRepository groupRepository = GroupRepository();
  final StudentRepository studentRepository = StudentRepository();
  final AttendanceRepository attendanceRepository = AttendanceRepository();
  final ExamRepository examRepository = ExamRepository();
  final PaymentRepository paymentRepository = PaymentRepository();
  final ReservationRepository reservationRepository = ReservationRepository();
  final NoteRepository noteRepository = NoteRepository();
  final SettingsRepository settingsRepository = SettingsRepository();
  final DashboardRepository dashboardRepository = DashboardRepository();
}
