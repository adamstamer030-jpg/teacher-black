import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../groups/groups_screen.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final _repo = Locator.instance.gradeRepository;
  List<Grade> _grades = [];
  Map<int, int> _studentCounts = {};
  Map<int, int> _groupCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final grades = await _repo.getAll();
    final studentCounts = <int, int>{};
    final groupCounts = <int, int>{};
    for (final g in grades) {
      studentCounts[g.id!] = await _repo.countStudentsInGrade(g.id!);
      groupCounts[g.id!] = await _repo.countGroupsInGrade(g.id!);
    }
    setState(() {
      _grades = grades;
      _studentCounts = studentCounts;
      _groupCounts = groupCounts;
      _loading = false;
    });
  }

  Future<void> _showForm({Grade? grade}) async {
    final controller = TextEditingController(text: grade?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(grade == null ? 'إضافة صف دراسي جديد' : 'تعديل الصف الدراسي'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثال: أولى ثانوي'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    if (grade == null) {
      await _repo.add(result);
    } else {
      await _repo.update(grade.copyWith(name: result));
    }
    _load();
  }

  Future<void> _delete(Grade grade) async {
    final count = _studentCounts[grade.id] ?? 0;
    final confirmed = await showConfirmDialog(
      context,
      title: 'حذف الصف الدراسي',
      message: count > 0
          ? 'يوجد $count طالب مرتبط بهذا الصف، سيتم فقط فصلهم عن الصف دون حذف بياناتهم. متابعة؟'
          : 'هل أنت متأكد من حذف "${grade.name}"؟',
    );
    if (!confirmed) return;
    await _repo.delete(grade.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفوف الدراسية'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? EmptyState(
                  icon: Icons.school_outlined,
                  message: 'لا توجد صفوف دراسية بعد\nابدأ بإضافة أول صف',
                  actionLabel: 'إضافة صف دراسي',
                  onAction: () => _showForm(),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _grades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final grade = _grades[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => GroupsScreen(gradeId: grade.id)),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            child: Icon(Icons.school_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(grade.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                              '${_groupCounts[grade.id] ?? 0} مجموعة • ${_studentCounts[grade.id] ?? 0} طالب'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _showForm(grade: grade);
                              if (v == 'delete') _delete(grade);
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'edit', child: Text('تعديل')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
