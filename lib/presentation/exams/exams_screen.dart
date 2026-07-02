import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import 'exam_form_screen.dart';
import 'exam_grading_screen.dart';

/// شاشة رئيسية للاختبارات: اختيار المجموعة لعرض اختباراتها
class ExamsHubScreen extends StatefulWidget {
  const ExamsHubScreen({super.key});

  @override
  State<ExamsHubScreen> createState() => _ExamsHubScreenState();
}

class _ExamsHubScreenState extends State<ExamsHubScreen> {
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
      appBar: AppBar(title: const Text('الاختبارات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const EmptyState(message: 'أضف مجموعة أولاً لإنشاء اختبارات', icon: Icons.layers_rounded)
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupExamsScreen(groupId: g.id!, groupName: g.name))),
                      ),
                    );
                  },
                ),
    );
  }
}

/// قائمة اختبارات مجموعة معينة
class GroupExamsScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  const GroupExamsScreen({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupExamsScreen> createState() => _GroupExamsScreenState();
}

class _GroupExamsScreenState extends State<GroupExamsScreen> {
  final _examRepo = Locator.instance.examRepository;
  List<Exam> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final exams = await _examRepo.getByGroup(widget.groupId);
    setState(() {
      _exams = exams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختبارات: ${widget.groupName}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ExamFormScreen(groupId: widget.groupId)));
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? const EmptyState(message: 'لا توجد اختبارات لهذه المجموعة بعد', icon: Icons.assignment_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final e = _exams[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.assignment_rounded)),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${AppHelpers.formatDate(e.date)} • الدرجة النهائية ${e.maxScore.toStringAsFixed(0)}'),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => ExamGradingScreen(exam: e)));
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
