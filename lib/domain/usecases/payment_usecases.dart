import '../../core/utils/helpers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/payment_repository.dart';

/// حالة استخدام: تسجيل دفعة مالية لطالب (اشتراك / رسوم إضافية / خصم)
/// وحساب "المتبقي" تلقائياً = المستحق - المدفوع
class RecordPaymentUseCase {
  final PaymentRepository repository;
  RecordPaymentUseCase(this.repository);

  Future<int> execute({
    required int studentId,
    int? groupId,
    required String type,
    required String title,
    required double dueAmount,
    required double amountPaid,
    String? monthYear,
    int? studentExtraFeeId,
    String? note,
    String? paymentDate,
  }) async {
    final payment = Payment(
      studentId: studentId,
      groupId: groupId,
      type: type,
      title: title,
      dueAmount: dueAmount,
      amount: amountPaid,
      monthYear: monthYear,
      studentExtraFeeId: studentExtraFeeId,
      note: note,
      paymentDate: paymentDate ?? AppHelpers.todayDateOnly(),
      createdAt: AppHelpers.nowIso(),
    );
    return repository.add(payment);
  }
}
