import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class ExamFormScreen extends StatefulWidget {
  final int groupId;
  final Exam? exam;
  const ExamFormScreen({super.key, required this.groupId, this.exam});

  @override
  State<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _examRepo = Locator.instance.examRepository;
  late TextEditingController _nameCtrl;
  late TextEditingController _curriculumCtrl;
  late TextEditingController _maxScoreCtrl;
  late TextEditingController _notesCtrl;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _curriculumCtrl = TextEditingController(text: e?.curriculum ?? '');
    _maxScoreCtrl = TextEditingController(text: e?.maxScore.toStringAsFixed(0) ?? '100');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) _date = DateTime.tryParse(e.date) ?? DateTime.now();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final exam = Exam(
      id: widget.exam?.id,
      groupId: widget.groupId,
      name: _nameCtrl.text.trim(),
      date: _date.toIso8601String(),
      curriculum: _curriculumCtrl.text.trim().isEmpty ? null : _curriculumCtrl.text.trim(),
      maxScore: double.tryParse(_maxScoreCtrl.text.trim()) ?? 100,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: AppHelpers.nowIso(),
    );
    if (widget.exam == null) {
      await _examRepo.add(exam);
    } else {
      await _examRepo.update(exam);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam == null ? 'إضافة اختبار جديد' : 'تعديل الاختبار')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(controller: _nameCtrl, label: 'اسم الاختبار', required: true, hint: 'اختبار الشهر الأول'),
            const SizedBox(height: 16),
            AppTextField(
              controller: TextEditingController(text: AppHelpers.formatDate(_date.toIso8601String())),
              label: 'تاريخ الاختبار',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.event_rounded),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _curriculumCtrl, label: 'المنهج', hint: 'الوحدة الأولى والثانية'),
            const SizedBox(height: 16),
            AppTextField(controller: _maxScoreCtrl, label: 'الدرجة النهائية', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            AppTextField(controller: _notesCtrl, label: 'ملاحظات', maxLines: 3),
            const SizedBox(height: 28),
            PrimaryButton(label: 'حفظ الاختبار', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
