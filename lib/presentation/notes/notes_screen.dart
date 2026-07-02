import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = Locator.instance.noteRepository;
  List<GeneralNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final notes = await _repo.getAll();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({GeneralNote? note}) async {
    final ctrl = TextEditingController(text: note?.text ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note == null ? 'إضافة ملاحظة' : 'تعديل الملاحظة'),
        content: TextField(controller: ctrl, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (result == true && ctrl.text.trim().isNotEmpty) {
      if (note == null) {
        await _repo.add(ctrl.text.trim());
      } else {
        await _repo.update(note.id!, ctrl.text.trim());
      }
      _load();
    }
  }

  Future<void> _delete(GeneralNote note) async {
    final confirmed = await showConfirmDialog(context, title: 'حذف الملاحظة', message: 'هل تريد حذف هذه الملاحظة؟');
    if (!confirmed) return;
    await _repo.delete(note.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملاحظات العامة')),
      floatingActionButton: FloatingActionButton(onPressed: () => _addOrEdit(), child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const EmptyState(message: 'لا توجد ملاحظات عامة بعد', icon: Icons.sticky_note_2_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final n = _notes[i];
                    return Card(
                      child: ListTile(
                        title: Text(n.text),
                        subtitle: Text(AppHelpers.formatDate(n.date)),
                        onTap: () => _addOrEdit(note: n),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(n)),
                      ),
                    );
                  },
                ),
    );
  }
}
