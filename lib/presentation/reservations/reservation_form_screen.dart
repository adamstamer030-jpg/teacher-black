import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class ReservationFormScreen extends StatefulWidget {
  final Reservation? reservation;
  const ReservationFormScreen({super.key, this.reservation});

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeRepo = Locator.instance.gradeRepository;
  final _repo = Locator.instance.reservationRepository;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _parentPhoneCtrl;
  late TextEditingController _notesCtrl;
  int? _gradeId;
  String _studySystem = AppConstants.studySystems.first;
  String _term = AppConstants.reservationTerms.first;
  String _status = 'جديد';
  List<Grade> _grades = [];
  bool _saving = false;

  bool get _isEdit => widget.reservation != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reservation;
    _nameCtrl = TextEditingController(text: r?.studentName ?? '');
    _phoneCtrl = TextEditingController(text: r?.phone ?? '');
    _parentPhoneCtrl = TextEditingController(text: r?.parentPhone ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _gradeId = r?.gradeId;
    _studySystem = r?.studySystem ?? AppConstants.studySystems.first;
    _term = r?.term ?? AppConstants.reservationTerms.first;
    _status = r?.status ?? 'جديد';
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    final grades = await _gradeRepo.getAll();
    setState(() => _grades = grades);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final reservation = Reservation(
      id: widget.reservation?.id,
      studentName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      parentPhone: _parentPhoneCtrl.text.trim().isEmpty ? null : _parentPhoneCtrl.text.trim(),
      gradeId: _gradeId,
      studySystem: _studySystem,
      term: _term,
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.reservation?.createdAt ?? AppHelpers.nowIso(),
    );

    if (_isEdit) {
      await _repo.update(reservation);
    } else {
      await _repo.add(reservation);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل الحجز' : 'حجز جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppDropdown<String>(
              label: 'نوع الحجز',
              value: _term,
              items: AppConstants.reservationTerms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _term = v ?? _term),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _nameCtrl, label: 'اسم الطالب', required: true),
            const SizedBox(height: 16),
            AppTextField(controller: _phoneCtrl, label: 'رقم الهاتف', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            AppTextField(controller: _parentPhoneCtrl, label: 'رقم هاتف ولي الأمر', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            AppDropdown<int>(
              label: 'الصف الدراسي',
              value: _gradeId,
              items: _grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
              onChanged: (v) => setState(() => _gradeId = v),
            ),
            const SizedBox(height: 16),
            Text('نظام الدراسة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.studySystems.map((s) => ChoiceChip(label: Text(s), selected: _studySystem == s, onSelected: (_) => setState(() => _studySystem = s))).toList(),
            ),
            const SizedBox(height: 16),
            Text('حالة الحجز', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.reservationStatuses.map((s) => ChoiceChip(label: Text(s), selected: _status == s, onSelected: (_) => setState(() => _status = s))).toList(),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _notesCtrl, label: 'ملاحظات', maxLines: 3),
            const SizedBox(height: 28),
            PrimaryButton(label: 'حفظ الحجز', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
