import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../students/student_detail_screen.dart';
import '../groups/group_detail_screen.dart';
import '../reservations/reservation_form_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _groupRepo = Locator.instance.groupRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  final _reservationRepo = Locator.instance.reservationRepository;

  String _query = '';
  List<Student> _students = [];
  List<StudyGroup> _groups = [];
  List<Grade> _grades = [];
  List<Reservation> _reservations = [];
  bool _searched = false;

  Future<void> _search(String q) async {
    _query = q;
    if (q.trim().isEmpty) {
      setState(() {
        _students = [];
        _groups = [];
        _grades = [];
        _reservations = [];
        _searched = false;
      });
      return;
    }

    final students = await _studentRepo.query(search: q);
    final allGroups = await _groupRepo.getAll();
    final groups = allGroups.where((g) => g.name.contains(q)).toList();
    final allGrades = await _gradeRepo.getAll();
    final grades = allGrades.where((g) => g.name.contains(q)).toList();
    final reservations = await _reservationRepo.getAll(search: q);

    setState(() {
      _students = students;
      _groups = groups;
      _grades = grades;
      _reservations = reservations;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final noResults = _searched && _students.isEmpty && _groups.isEmpty && _grades.isEmpty && _reservations.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ابحث في الطلاب، المجموعات، الصفوف، الحجوزات...', border: InputBorder.none),
          onChanged: _search,
        ),
      ),
      body: noResults
          ? const EmptyState(message: 'لا توجد نتائج مطابقة', icon: Icons.search_off_rounded)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_students.isNotEmpty) ...[
                  SectionTitle(title: 'الطلاب', icon: Icons.groups_rounded),
                  const SizedBox(height: 8),
                  ..._students.map((s) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: InitialAvatar(name: s.name),
                          title: Text(s.name),
                          subtitle: Text('كود: ${s.code}'),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id!))),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_groups.isNotEmpty) ...[
                  SectionTitle(title: 'المجموعات', icon: Icons.layers_rounded),
                  const SizedBox(height: 8),
                  ..._groups.map((g) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.layers_rounded),
                          title: Text(g.name),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: g.id!))),
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_grades.isNotEmpty) ...[
                  SectionTitle(title: 'الصفوف الدراسية', icon: Icons.school_rounded),
                  const SizedBox(height: 8),
                  ..._grades.map((g) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(leading: const Icon(Icons.school_rounded), title: Text(g.name)),
                      )),
                  const SizedBox(height: 16),
                ],
                if (_reservations.isNotEmpty) ...[
                  SectionTitle(title: 'الحجوزات', icon: Icons.calendar_month_rounded),
                  const SizedBox(height: 8),
                  ..._reservations.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event_note_rounded),
                          title: Text(r.studentName),
                          subtitle: Text(r.status),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationFormScreen(reservation: r))),
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}
