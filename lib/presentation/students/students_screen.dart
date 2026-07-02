import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import 'student_detail_screen.dart';
import 'student_form_screen.dart';

class StudentsScreen extends StatefulWidget {
  final int? initialGroupId;
  const StudentsScreen({super.key, this.initialGroupId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _repo = Locator.instance.studentRepository;
  List<Student> _students = [];
  bool _loading = true;
  String _search = '';
  String _sort = AppConstants.studentSortOptions.first;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _repo.query(
      search: _search,
      groupId: widget.initialGroupId,
      includeArchived: _showArchived,
      sort: _sort,
    );
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.studentSortOptions
              .map((s) => ListTile(
                    title: Text(s),
                    trailing: s == _sort ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () => Navigator.pop(ctx, s),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _sort = selected);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الطلاب المقيدين'),
        actions: [
          IconButton(icon: const Icon(Icons.sort_rounded), onPressed: _openSortSheet),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archived') setState(() => _showArchived = !_showArchived);
              _load();
            },
            itemBuilder: (ctx) => [
              CheckedPopupMenuItem(value: 'archived', checked: _showArchived, child: const Text('عرض المؤرشفين')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => StudentFormScreen(initialGroupId: widget.initialGroupId)));
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'بحث عن طالب بالاسم أو الكود أو الهاتف...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) {
                _search = v;
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(message: 'لا يوجد طلاب مطابقين', icon: Icons.person_off_rounded)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final s = _students[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: InitialAvatar(name: s.name),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${s.phone ?? 'بدون رقم'}'),
                              trailing: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                child: Text(s.code, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id!)));
                                _load();
                              },
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
