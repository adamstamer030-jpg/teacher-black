import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../grades/grades_screen.dart';
import '../groups/groups_screen.dart';
import '../attendance/attendance_screen.dart';
import '../reservations/reservations_screen.dart';
import '../notes/notes_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../students/students_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = Locator.instance.dashboardRepository;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _repo.load();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              // نفتح الـ Drawer بتاع MainShell (الـ ancestor Scaffold)
              final scaffold = Scaffold.maybeOf(ctx);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              } else {
                // fallback: ندور على MainShell scaffold
                context.findAncestorStateOfType<ScaffoldState>()?.openDrawer();
              }
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBanner(context),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatCard(
                        title: 'إجمالي الطلاب',
                        value: '${stats.studentsCount}',
                        icon: Icons.groups_rounded,
                        color: Colors.indigo,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentsScreen())),
                      ),
                      StatCard(
                        title: 'المجموعات',
                        value: '${stats.groupsCount}',
                        icon: Icons.layers_rounded,
                        color: Colors.orange,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())),
                      ),
                      StatCard(
                        title: 'الصفوف الدراسية',
                        value: '${stats.gradesCount}',
                        icon: Icons.menu_book_rounded,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GradesScreen())),
                      ),
                      StatCard(
                        title: 'الاختبارات',
                        value: '${stats.examsCount}',
                        icon: Icons.assignment_rounded,
                        color: Colors.blue,
                      ),
                      StatCard(
                        title: 'مدفوعات الشهر',
                        value: AppHelpers.formatMoney(stats.paymentsThisMonth),
                        icon: Icons.payments_rounded,
                        color: Colors.teal,
                      ),
                      StatCard(
                        title: 'متأخرون في الدفع',
                        value: '${stats.lateStudentsCount}',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      StatCard(
                        title: 'الحجوزات',
                        value: '${stats.reservationsCount}',
                        icon: Icons.calendar_month_rounded,
                        color: Colors.purple,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationsScreen())),
                      ),
                      StatCard(
                        title: 'ملاحظات عامة',
                        value: '•',
                        icon: Icons.sticky_note_2_rounded,
                        color: Colors.blueGrey,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: 'جدول حصص اليوم',
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (stats.todaySchedule.isEmpty)
                    const EmptyState(message: 'لا توجد حصص مجدولة اليوم', icon: Icons.event_busy_rounded)
                  else
                    ...stats.todaySchedule.map((row) {
                      final color = Color(int.parse((row['group_color'] as String).replaceFirst('#', '0xff')));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            width: 6,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                          ),
                          title: Text(row['group_name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${row['location'] ?? ''}'),
                          trailing: Text('${row['start_time']} - ${row['end_time']}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  SectionTitle(title: 'الأقسام الرئيسية', icon: Icons.apps_rounded),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      _SectionIcon(icon: Icons.fact_check_rounded, label: 'الحضور', color: Colors.teal, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceGroupPickerScreen()))),
                      _SectionIcon(icon: Icons.layers_rounded, label: 'المجموعات', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen()))),
                      _SectionIcon(icon: Icons.school_rounded, label: 'الصفوف', color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GradesScreen()))),
                      _SectionIcon(icon: Icons.calendar_month_rounded, label: 'الحجوزات', color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationsScreen()))),
                      _SectionIcon(icon: Icons.sticky_note_2_rounded, label: 'الملاحظات', color: Colors.blueGrey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()))),
                      _SectionIcon(icon: Icons.settings_rounded, label: 'الإعدادات', color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('منظّم دروسك … نجاح طلابك',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
                SizedBox(height: 8),
                Text('كل ما تحتاجه لإدارة مركزك التعليمي في مكان واحد',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white, size: 46),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SectionIcon({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}
