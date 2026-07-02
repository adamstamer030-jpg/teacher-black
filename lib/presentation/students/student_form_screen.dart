import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../domain/usecases/student_usecases.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  final int? initialGroupId;
  const StudentFormScreen({super.key, this.student, this.initialGroupId});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentRepo = Locator.instance.studentRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  final _groupRepo = Locator.instance.groupRepository;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _parentPhoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _codeCtrl;

  int? _gradeId;
  int? _groupId;
  String? _gender;
  DateTime? _birthDate;
  DateTime _subscriptionDate = DateTime.now();
  bool _useCustomSubscriptionDate = false;
  bool _editCodeManually = false;
  String? _photoPath;

  List<Grade> _grades = [];
  List<StudyGroup> _groups = [];
  bool _saving = false;

  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _parentPhoneCtrl = TextEditingController(text: s?.parentPhone ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _schoolCtrl = TextEditingController(text: s?.school ?? '');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _codeCtrl = TextEditingController(text: s?.code ?? '');
    _gradeId = s?.gradeId;
    _groupId = s?.groupId ?? widget.initialGroupId;
    _gender = s?.gender;
    _photoPath = s?.photoPath;
    if (s?.birthDate != null) _birthDate = DateTime.tryParse(s!.birthDate!);
    if (s?.subscriptionDate != null) {
      _subscriptionDate = DateTime.tryParse(s!.subscriptionDate) ?? DateTime.now();
      _useCustomSubscriptionDate = true;
    }
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final grades = await _gradeRepo.getAll();
    final groups = _gradeId != null ? await _groupRepo.getByGrade(_gradeId!) : await _groupRepo.getAll();
    setState(() {
      _grades = grades;
      _groups = groups;
    });
  }

  Future<void> _onGradeChanged(int? gradeId) async {
    setState(() {
      _gradeId = gradeId;
      _groupId = null;
    });
    if (gradeId != null) {
      final groups = await _groupRepo.getByGrade(gradeId);
      setState(() => _groups = groups);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('تصوير بالكاميرا'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('اختيار من المعرض'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) setState(() => _photoPath = file.path);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2010, 1, 1),
      firstDate: DateTime(1995),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickSubscriptionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _subscriptionDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _subscriptionDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (!_isEdit) {
        final useCase = CreateStudentUseCase(_studentRepo);
        await useCase.execute(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          parentPhone: _parentPhoneCtrl.text.trim().isEmpty ? null : _parentPhoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          school: _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
          gradeId: _gradeId,
          groupId: _groupId,
          gender: _gender,
          birthDate: _birthDate?.toIso8601String(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          photoPath: _photoPath,
          subscriptionDate: (_useCustomSubscriptionDate ? _subscriptionDate : DateTime.now()).toIso8601String(),
          manualCode: _editCodeManually ? _codeCtrl.text.trim() : null,
        );
      } else {
        final updateCase = UpdateStudentUseCase(_studentRepo);
        await updateCase.execute(widget.student!.copyWith(
          code: _codeCtrl.text.trim().isEmpty ? widget.student!.code : _codeCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          parentPhone: _parentPhoneCtrl.text.trim().isEmpty ? null : _parentPhoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          school: _schoolCtrl.text.trim().isEmpty ? null : _schoolCtrl.text.trim(),
          gradeId: _gradeId,
          groupId: _groupId,
          gender: _gender,
          birthDate: _birthDate?.toIso8601String(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          photoPath: _photoPath,
          subscriptionDate: _subscriptionDate.toIso8601String(),
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } on DuplicatePhoneException {
      if (mounted) showAppSnackBar(context, 'رقم الهاتف مستخدم لطالب آخر بالفعل', error: true);
    } on DuplicateCodeException {
      if (mounted) showAppSnackBar(context, 'هذا الكود مستخدم لطالب آخر بالفعل', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل بيانات الطالب' : 'إضافة طالب جديد للنظام')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? Icon(Icons.add_a_photo_rounded, color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _nameCtrl, label: 'اسم الطالب رباعي بالكامل', required: true, hint: 'مثال: أحمد محمد جلال'),
            const SizedBox(height: 16),
            AppTextField(controller: _phoneCtrl, label: 'رقم هاتف الطالب', keyboardType: TextInputType.phone, hint: '01xxxxxxxxx'),
            const SizedBox(height: 16),
            AppTextField(controller: _parentPhoneCtrl, label: 'رقم هاتف ولي الأمر', keyboardType: TextInputType.phone, hint: '01xxxxxxxxx'),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'الصف الدراسي',
              value: _gradeId,
              items: _grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: _onGradeChanged,
            ),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'المجموعة المقررة له',
              value: _groupId,
              items: _groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: (v) => setState(() => _groupId = v),
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'النوع',
              value: _gender,
              items: AppConstants.genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _schoolCtrl, label: 'المدرسة'),
            const SizedBox(height: 16),
            AppTextField(controller: _addressCtrl, label: 'العنوان'),
            const SizedBox(height: 16),
            AppTextField(
              controller: TextEditingController(text: _birthDate != null ? intl.DateFormat('yyyy/MM/dd').format(_birthDate!) : ''),
              label: 'تاريخ الميلاد',
              readOnly: true,
              onTap: _pickBirthDate,
              suffixIcon: const Icon(Icons.cake_outlined),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تحديد تاريخ اشتراك مخصص', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('عند الإيقاف يُستخدم تاريخ اليوم تلقائياً'),
              value: _useCustomSubscriptionDate,
              onChanged: (v) => setState(() => _useCustomSubscriptionDate = v),
            ),
            if (_useCustomSubscriptionDate)
              AppTextField(
                controller: TextEditingController(text: intl.DateFormat('yyyy/MM/dd').format(_subscriptionDate)),
                label: 'تاريخ الاشتراك',
                readOnly: true,
                onTap: _pickSubscriptionDate,
                suffixIcon: const Icon(Icons.event_rounded),
              ),
            const SizedBox(height: 16),
            AppTextField(controller: _notesCtrl, label: 'ملاحظات', maxLines: 3),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تعديل كود الطالب يدوياً', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('بشكل افتراضي يتم توليد الكود تلقائياً وبشكل فريد'),
              value: _editCodeManually,
              onChanged: (v) => setState(() => _editCodeManually = v),
            ),
            if (_editCodeManually || _isEdit)
              AppTextField(controller: _codeCtrl, label: 'كود الطالب', keyboardType: TextInputType.number),
            const SizedBox(height: 28),
            PrimaryButton(
              label: _isEdit ? 'حفظ التعديلات' : 'حفظ الطالب وتوليد كود تلقائي',
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
