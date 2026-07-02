import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/db/app_database.dart';
import '../../data/models/models.dart';
import 'payment_form_screen.dart';
import 'payments_report_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, s.name as student_name, s.code as student_code
      FROM payments p
      JOIN students s ON s.id = p.student_id
      ORDER BY p.id DESC
      LIMIT 100
    ''');
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدفوعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsReportScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PaymentFormScreen()));
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(message: 'لا توجد مدفوعات مسجلة بعد', icon: Icons.payments_rounded)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final r = _rows[i];
                      final amount = (r['amount'] as num).toDouble();
                      final due = (r['due_amount'] as num).toDouble();
                      final remaining = due > amount ? due - amount : 0;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.payments_rounded, color: Colors.green)),
                          title: Text('${r['student_name']} - ${r['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r['type']} • ${AppHelpers.formatDate(r['payment_date'] as String)}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(AppHelpers.formatMoney(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              if (remaining > 0) Text('متبقي ${AppHelpers.formatMoney(remaining.toDouble())}', style: const TextStyle(fontSize: 11, color: Colors.red)),
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
