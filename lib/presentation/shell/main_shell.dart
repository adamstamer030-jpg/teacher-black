import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../students/students_screen.dart';
import '../students/student_form_screen.dart';
import '../exams/exams_screen.dart';
import '../payments/payments_screen.dart';
import '../payments/payment_form_screen.dart';
import '../grades/grades_screen.dart';
import '../groups/groups_screen.dart';
import '../groups/group_form_screen.dart';
import '../attendance/attendance_screen.dart';
import '../reservations/reservations_screen.dart';
import '../reservations/reservation_form_screen.dart';
import '../notes/notes_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    StudentsScreen(),
    ExamsHubScreen(),
    PaymentsScreen(),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _AppDrawer(onNavigate: _goTo),
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'الرئيسية', index: 0, current: _index, onTap: _goTo),
            _NavItem(icon: Icons.groups_rounded, label: 'الطلاب', index: 1, current: _index, onTap: _goTo),
            const SizedBox(width: 48),
            _NavItem(icon: Icons.assignment_rounded, label: 'الاختبارات', index: 2, current: _index, onTap: _goTo),
            _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'المدفوعات', index: 3, current: _index, onTap: _goTo),
          ],
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text('إضافة سريعة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _QuickAction(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'طالب جديد',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen()));
                    },
                  ),
                  _QuickAction(
                    icon: Icons.layers_rounded,
                    label: 'مجموعة جديدة',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupFormScreen()));
                    },
                  ),
                  _QuickAction(
                    icon: Icons.payments_rounded,
                    label: 'تسجيل دفعة',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFormScreen()));
                    },
                  ),
                  _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: 'حجز جديد',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationFormScreen()));
                    },
                  ),
                  _QuickAction(
                    icon: Icons.fact_check_rounded,
                    label: 'تسجيل حضور',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceGroupPickerScreen()));
                    },
                  ),
                  _QuickAction(
                    icon: Icons.note_add_rounded,
                    label: 'ملاحظة',
                    color: Colors.blueGrey,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

/// قائمة جانبية تجمع كل أقسام التطبيق (مطابقة لفكرة القائمة بالتصميم المرجعي)
class _AppDrawer extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _AppDrawer({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = <_DrawerItemData>[
      _DrawerItemData(Icons.home_rounded, 'الشاشة الرئيسية', () {
        Navigator.pop(context);
        onNavigate(0);
      }),
      _DrawerItemData(Icons.school_rounded, 'الصفوف الدراسية', () => _push(context, const GradesScreen())),
      _DrawerItemData(Icons.layers_rounded, 'المجموعات', () => _push(context, const GroupsScreen())),
      _DrawerItemData(Icons.groups_rounded, 'إدارة الطلاب', () {
        Navigator.pop(context);
        onNavigate(1);
      }),
      _DrawerItemData(Icons.fact_check_rounded, 'الحضور والغياب', () => _push(context, const AttendanceGroupPickerScreen())),
      _DrawerItemData(Icons.assignment_rounded, 'الاختبارات', () {
        Navigator.pop(context);
        onNavigate(2);
      }),
      _DrawerItemData(Icons.account_balance_wallet_rounded, 'المدفوعات', () {
        Navigator.pop(context);
        onNavigate(3);
      }),
      _DrawerItemData(Icons.calendar_month_rounded, 'الحجوزات', () => _push(context, const ReservationsScreen())),
      _DrawerItemData(Icons.sticky_note_2_rounded, 'الملاحظات العامة', () => _push(context, const NotesScreen())),
      _DrawerItemData(Icons.search_rounded, 'البحث الشامل', () => _push(context, const SearchScreen())),
      _DrawerItemData(Icons.settings_rounded, 'الإعدادات', () => _push(context, const SettingsScreen())),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('قائمة التطبيق الشاملة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return ListTile(
                    leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                    title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: item.onTap,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _DrawerItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _DrawerItemData(this.icon, this.label, this.onTap);
}
