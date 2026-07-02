import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

/// شاشة اختيار المجموعة قبل تسجيل الحضور
class AttendanceGroupPickerScreen extends StatefulWidget {
  const AttendanceGroupPickerScreen({super.key});

  @override
  State<AttendanceGroupPickerScreen> createState() => _AttendanceGroupPickerScreenState();
}

class _AttendanceGroupPickerScreenState extends State<AttendanceGroupPickerScreen> {
  final _groupRepo = Locator.instance.groupRepository;
  List<StudyGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await _groupRepo.getAll();
    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الحضور والغياب')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const EmptyState(message: 'أضف مجموعة أولاً لتسجيل الحضور', icon: Icons.layers_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final g = _groups[i];
                    final color = Color(int.parse(g.color.replaceFirst('#', '0xff')));
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.layers_rounded, color: color)),
                        title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AttendanceScreen(groupId: g.id!, groupName: g.name)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// شاشة تسجيل الحضور لمجموعة معينة في تاريخ محدد
class AttendanceScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  const AttendanceScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _attendanceRepo = Locator.instance.attendanceRepository;
  List<Student> _students = [];
  Map<int, AttendanceRecord> _records = {};
  DateTime _date = DateTime.now();
  bool _loading = true;

  String get _dateKey => _date.toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _studentRepo.getByGroup(widget.groupId);
    final records = await _attendanceRepo.getForGroupAndDate(widget.groupId, _dateKey);
    setState(() {
      _students = students;
      _records = records;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _mark(Student s, String status) async {
    await _attendanceRepo.markAttendance(groupId: widget.groupId, studentId: s.id!, date: _dateKey, status: status);
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'حاضر':
        return Colors.green;
      case 'غائب':
        return Colors.red;
      case 'متأخر':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حضور: ${widget.groupName}'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month_rounded), onPressed: _pickDate),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Text('التاريخ: ${AppHelpers.formatDate(_dateKey)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(message: 'لا يوجد طلاب في هذه المجموعة', icon: Icons.groups_rounded)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final s = _students[i];
                          final current = _records[s.id]?.status;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  InitialAvatar(name: s.name, size: 38),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                  Wrap(
                                    spacing: 4,
                                    children: AppConstants.attendanceStatuses.map((status) {
                                      final selected = current == status;
                                      final color = _statusColor(status);
                                      return GestureDetector(
                                        onTap: () => _mark(s, status),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: selected ? color : color.withOpacity(0.12),
                                          child: Text(status[0], style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
