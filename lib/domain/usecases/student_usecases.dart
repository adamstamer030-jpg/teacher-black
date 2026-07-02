import '../../core/utils/helpers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/student_repository.dart';

class DuplicatePhoneException implements Exception {
  final String message;
  DuplicatePhoneException([this.message = 'يوجد طالب آخر بنفس رقم الهاتف بالفعل']);
  @override
  String toString() => message;
}

class DuplicateCodeException implements Exception {
  final String message;
  DuplicateCodeException([this.message = 'هذا الكود مستخدم من قبل طالب آخر']);
  @override
  String toString() => message;
}

/// حالة استخدام: إضافة طالب جديد
/// - تولّد كوداً تلقائياً فريداً (أو تتحقق من الكود اليدوي المُدخل)
/// - تتحقق من عدم تكرار رقم الهاتف
class CreateStudentUseCase {
  final StudentRepository repository;
  CreateStudentUseCase(this.repository);

  Future<int> execute({
    required String name,
    String? phone,
    String? parentPhone,
    String? address,
    String? school,
    int? gradeId,
    int? groupId,
    String? gender,
    String? birthDate,
    String? notes,
    String? photoPath,
    required String subscriptionDate,
    String? manualCode,
  }) async {
    if (phone != null && phone.trim().isNotEmpty) {
      final dup = await repository.isPhoneDuplicate(phone.trim());
      if (dup) throw DuplicatePhoneException();
    }

    String code;
    if (manualCode != null && manualCode.trim().isNotEmpty) {
      final taken = await repository.isCodeTaken(manualCode.trim());
      if (taken) throw DuplicateCodeException();
      code = manualCode.trim();
    } else {
      code = await repository.generateNextCode();
    }

    final student = Student(
      code: code,
      name: name.trim(),
      phone: phone?.trim(),
      parentPhone: parentPhone?.trim(),
      address: address,
      school: school,
      gradeId: gradeId,
      groupId: groupId,
      gender: gender,
      birthDate: birthDate,
      notes: notes,
      photoPath: photoPath,
      subscriptionDate: subscriptionDate,
      createdAt: AppHelpers.nowIso(),
    );

    return repository.add(student);
  }
}

/// حالة استخدام: تحديث بيانات طالب موجود مع نفس قواعد التحقق
class UpdateStudentUseCase {
  final StudentRepository repository;
  UpdateStudentUseCase(this.repository);

  Future<void> execute(Student updated) async {
    if (updated.phone != null && updated.phone!.trim().isNotEmpty) {
      final dup = await repository.isPhoneDuplicate(updated.phone!.trim(),
          excludeId: updated.id);
      if (dup) throw DuplicatePhoneException();
    }
    final taken =
        await repository.isCodeTaken(updated.code, excludeId: updated.id);
    if (taken) throw DuplicateCodeException();

    await repository.update(updated);
  }
}

/// حالة استخدام: نقل طالب بين مجموعة/صف مع الاحتفاظ بكل سجلاته
class TransferStudentUseCase {
  final StudentRepository repository;
  TransferStudentUseCase(this.repository);

  Future<void> execute(int studentId, {int? newGroupId, int? newGradeId}) {
    return repository.transfer(studentId,
        newGroupId: newGroupId, newGradeId: newGradeId);
  }
}
