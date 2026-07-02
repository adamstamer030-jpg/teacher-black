import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../../domain/usecases/payment_usecases.dart';

class PaymentFormScreen extends StatefulWidget {
  final int? studentId;
  final int? groupId;
  const PaymentFormScreen({super.key, this.studentId, this.groupId});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _groupRepo = Locator.instance.groupRepository;
  final _paymentRepo = Locator.instance.paymentRepository;

  Student? _student;
  StudyGroup? _group;
  String _type = 'اشتراك';
  String _searchText = '';
  List<Student> _searchResults = [];
  List<StudentExtraFee> _unpaidFees = [];
  StudentExtraFee? _selectedFee;

  late TextEditingController _titleCtrl;
  late TextEditingController _dueCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _dueCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    if (widget.studentId != null) _loadStudent(widget.studentId!);
  }

  Future<void> _loadStudent(int id) async {
    final s = await _studentRepo.getById(id);
    final group = s?.groupId != null ? await _groupRepo.getById(s!.groupId!) : null;
    final fees = s != null ? await _paymentRepo.getStudentExtraFees(s.id!) : <StudentExtraFee>[];
    setState(() {
      _student = s;
      _group = group;
      _unpaidFees = fees.where((f) => !f.isPaid).toList();
      if (_type == 'اشتراك' && group != null) {
        _titleCtrl.text = 'اشتراك ${AppHelpers.monthYearLabel(AppHelpers.monthYearKey(_date))}';
        _dueCtrl.text = group.monthlyFee.toStringAsFixed(0);
        _amountCtrl.text = group.monthlyFee.toStringAsFixed(0);
      }
    });
  }

  Future<void> _search(String text) async {
    _searchText = text;
    if (text.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _studentRepo.query(search: text);
    setState(() => _searchResults = results);
  }

  void _onTypeChanged(String type) {
    setState(() {
      _type = type;
      _selectedFee = null;
      if (type == 'اشتراك' && _group != null) {
        _titleCtrl.text = 'اشتراك ${AppHelpers.monthYearLabel(AppHelpers.monthYearKey(_date))}';
        _dueCtrl.text = _group!.monthlyFee.toStringAsFixed(0);
        _amountCtrl.text = _group!.monthlyFee.toStringAsFixed(0);
      } else if (type == 'خصم') {
        _titleCtrl.text = 'خصم';
        _dueCtrl.text = '0';
      } else {
        _titleCtrl.clear();
        _dueCtrl.clear();
        _amountCtrl.clear();
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) {
      setState(() => _date = picked);
      if (_type == 'اشتراك') {
        _titleCtrl.text = 'اشتراك ${AppHelpers.monthYearLabel(AppHelpers.monthYearKey(_date))}';
      }
    }
  }

  Future<void> _save() async {
    if (_student == null) {
      showAppSnackBar(context, 'برجاء اختيار الطالب أولاً', error: true);
      return;
    }
    final due = double.tryParse(_dueCtrl.text.trim()) ?? 0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (_titleCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'برجاء كتابة عنوان للدفعة', error: true);
      return;
    }

    setState(() => _saving = true);
    final useCase = RecordPaymentUseCase(_paymentRepo);
    await useCase.execute(
      studentId: _student!.id!,
      groupId: _student!.groupId,
      type: _type,
      title: _titleCtrl.text.trim(),
      dueAmount: due,
      amountPaid: amount,
      monthYear: _type == 'اشتراك' ? AppHelpers.monthYearKey(_date) : null,
      studentExtraFeeId: _selectedFee?.id,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      paymentDate: _date.toIso8601String().split('T').first,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دفعة مالية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_student == null) ...[
            AppTextField(
              controller: TextEditingController(text: _searchText),
              label: 'البحث عن الطالب',
              hint: 'اكتب اسم الطالب أو كوده',
              suffixIcon: const Icon(Icons.search_rounded),
            ),
            const SizedBox(height: 4),
            TextField(
              decoration: const InputDecoration(hintText: 'بحث سريع...'),
              onChanged: _search,
            ),
            const SizedBox(height: 10),
            ..._searchResults.map((s) => ListTile(
                  leading: InitialAvatar(name: s.name, size: 36),
                  title: Text(s.name),
                  subtitle: Text('كود: ${s.code}'),
                  onTap: () => _loadStudent(s.id!),
                )),
          ] else ...[
            Card(
              child: ListTile(
                leading: InitialAvatar(name: _student!.name),
                title: Text(_student!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_group?.name ?? ''),
                trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _student = null)),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ['اشتراك', 'رسوم إضافية', 'خصم'].map((t) {
                final selected = _type == t;
                return ChoiceChip(label: Text(t), selected: selected, onSelected: (_) => _onTypeChanged(t));
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_type == 'رسوم إضافية' && _unpaidFees.isNotEmpty) ...[
              Text('اختر رسماً غير مدفوع', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _unpaidFees.map((f) {
                  final selected = _selectedFee?.id == f.id;
                  return ChoiceChip(
                    label: Text('${f.name} (${f.price.toStringAsFixed(0)})'),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedFee = f;
                      _titleCtrl.text = f.name;
                      _dueCtrl.text = f.price.toStringAsFixed(0);
                      _amountCtrl.text = f.price.toStringAsFixed(0);
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(controller: _titleCtrl, label: 'عنوان الدفعة', required: true),
            const SizedBox(height: 16),
            AppTextField(
              controller: TextEditingController(text: AppHelpers.formatDate(_date.toIso8601String())),
              label: 'تاريخ الدفعة',
              readOnly: true,
              onTap: _pickDate,
              suffixIcon: const Icon(Icons.event_rounded),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: AppTextField(controller: _dueCtrl, label: 'المستحق', keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(controller: _amountCtrl, label: 'المدفوع', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _noteCtrl, label: 'ملاحظات', maxLines: 2),
            const SizedBox(height: 28),
            PrimaryButton(label: 'حفظ الدفعة', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
          ],
        ],
      ),
    );
  }
}
