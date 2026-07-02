import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class GroupFormScreen extends StatefulWidget {
  final StudyGroup? group;
  final int? initialGradeId;
  const GroupFormScreen({super.key, this.group, this.initialGradeId});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeRepo = Locator.instance.gradeRepository;
  final _groupRepo = Locator.instance.groupRepository;

  final _nameCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Grade> _grades = [];
  int? _gradeId;
  String _color = '#6366F1';
  bool _saving = false;

  bool get _isEdit => widget.group != null;

  @override
  void initState() {
    super.initState();
    _gradeId = widget.group?.gradeId ?? widget.initialGradeId;
    if (widget.group != null) {
      final g = widget.group!;
      _nameCtrl.text = g.name;
      _feeCtrl.text = g.monthlyFee.toStringAsFixed(0);
      _notesCtrl.text = g.notes ?? '';
      _color = g.color;
    }
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await _gradeRepo.getAll();
    setState(() {
      _grades = grades;
      _gradeId ??= grades.isNotEmpty ? grades.first.id : null;
    });
  }

  String _colorToHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gradeId == null) {
      showAppSnackBar(context, 'يجب إضافة صف دراسي أولاً', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final group = StudyGroup(
        id: widget.group?.id,
        gradeId: _gradeId!,
        name: _nameCtrl.text.trim(),
        color: _color,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        monthlyFee: double.tryParse(_feeCtrl.text.trim()) ?? 0,
        createdAt: widget.group?.createdAt ?? AppHelpers.nowIso(),
      );
      if (!_isEdit) {
        await _groupRepo.add(group);
      } else {
        await _groupRepo.update(group);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل المجموعة' : 'مجموعة دراسية جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(controller: _nameCtrl, label: 'اسم المجموعة', required: true, hint: 'مثال: مجموعة أولى ثانوي (أ)'),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'الصف الدراسي',
              required: true,
              value: _gradeId,
              items: _grades
                  .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                  .toList(),
              onChanged: (v) => setState(() => _gradeId = v),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _feeCtrl,
              label: 'الاشتراك الشهري (جنيه مصري)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text('لون المجموعة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColors.palette.map((c) {
                final hex = _colorToHex(c);
                final selected = hex == _color;
                return InkWell(
                  onTap: () => setState(() => _color = hex),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                    child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _notesCtrl, label: 'ملاحظات', maxLines: 3),
            const SizedBox(height: 28),
            PrimaryButton(
              label: _isEdit ? 'حفظ التعديلات' : 'حفظ المجموعة',
              icon: Icons.save_rounded,
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
