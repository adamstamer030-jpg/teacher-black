import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class ExamGradingScreen extends StatefulWidget {
  final Exam exam;
  const ExamGradingScreen({super.key, required this.exam});

  @override
  State<ExamGradingScreen> createState() => _ExamGradingScreenState();
}

class _ExamGradingScreenState extends State<ExamGradingScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _examRepo = Locator.instance.examRepository;
  List<Student> _students = [];
  Map<int, ExamResult> _results = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final students = await _studentRepo.getByGroup(widget.exam.groupId);
    final results = await _examRepo.getResultsForExam(widget.exam.id!);
    setState(() {
      _students = students;
      _results = results;
      _loading = false;
    });
  }

  Future<void> _editScore(Student s) async {
    final existing = _results[s.id];
    final scoreCtrl = TextEditingController(text: existing?.score?.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            AppTextField(controller: scoreCtrl, label: 'الدرجة من ${widget.exam.maxScore.toStringAsFixed(0)}', keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppTextField(controller: notesCtrl, label: 'ملاحظات', maxLines: 2),
            const SizedBox(height: 20),
            PrimaryButton(label: 'حفظ الدرجة', onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (result == true) {
      final resultId = await _examRepo.saveResult(
        examId: widget.exam.id!,
        studentId: s.id!,
        score: double.tryParse(scoreCtrl.text.trim()),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      _load();
      if (mounted) _showAttachmentsSheet(s, resultId);
    }
  }

  Future<void> _showAttachmentsSheet(Student s, int examResultId) async {
    final attachments = await _examRepo.getAttachments(examResultId);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('صور ورقة الامتحان - ${s.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (attachments.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('لا توجد صور مضافة بعد'))
              else
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: attachments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final a = attachments[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(a.filePath), width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2, left: 2,
                            child: GestureDetector(
                              onTap: () async {
                                await _examRepo.deleteAttachment(a.id!);
                                attachments.removeAt(i);
                                setSheetState(() {});
                              },
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('تصوير'),
                      onPressed: () async {
                        final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
                        if (file != null) {
                          await _examRepo.addAttachment(examResultId, file.path);
                          final updated = await _examRepo.getAttachments(examResultId);
                          attachments
                            ..clear()
                            ..addAll(updated);
                          setSheetState(() {});
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('من المعرض'),
                      onPressed: () async {
                        final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (file != null) {
                          await _examRepo.addAttachment(examResultId, file.path);
                          final updated = await _examRepo.getAttachments(examResultId);
                          attachments
                            ..clear()
                            ..addAll(updated);
                          setSheetState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam.name)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Text(
              '${AppHelpers.formatDate(widget.exam.date)} • الدرجة النهائية ${widget.exam.maxScore.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
                          final result = _results[s.id];
                          return Card(
                            child: ListTile(
                              leading: InitialAvatar(name: s.name),
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: result?.notes != null ? Text(result!.notes!) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    result?.score != null ? result!.score!.toStringAsFixed(1) : '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_outlined, size: 18),
                                ],
                              ),
                              onTap: () => _editScore(s),
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
