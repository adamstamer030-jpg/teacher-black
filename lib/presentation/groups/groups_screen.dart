import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import 'group_detail_screen.dart';
import 'group_form_screen.dart';

class GroupsScreen extends StatefulWidget {
  final int? gradeId;
  const GroupsScreen({super.key, this.gradeId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupRepo = Locator.instance.groupRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  List<StudyGroup> _groups = [];
  Map<int, Grade> _grades = {};
  Map<int, int> _studentCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final grades = await _gradeRepo.getAll();
    final gradesMap = {for (final g in grades) g.id!: g};
    final groups = widget.gradeId != null
        ? await _groupRepo.getByGrade(widget.gradeId!)
        : await _groupRepo.getAll();
    final counts = <int, int>{};
    for (final g in groups) {
      counts[g.id!] = await _groupRepo.countStudents(g.id!);
    }
    setState(() {
      _grades = gradesMap;
      _groups = groups;
      _studentCounts = counts;
      _loading = false;
    });
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجموعات الدراسية المتاحة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? EmptyState(
                  icon: Icons.layers_outlined,
                  message: 'لا توجد مجموعات بعد\nابدأ بإضافة أول مجموعة',
                  actionLabel: 'إضافة مجموعة',
                  onAction: () => _openForm(),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final group = _groups[i];
                      final color = _parseColor(group.color);
                      final grade = _grades[group.gradeId];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id!)),
                            );
                            _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(width: 5, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      const SizedBox(height: 3),
                                      Text(grade?.name ?? '', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                StatusBadge(label: '${_studentCounts[group.id] ?? 0} طالب مقيد', color: color),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupFormScreen(initialGradeId: widget.gradeId)),
    );
    _load();
  }
}
