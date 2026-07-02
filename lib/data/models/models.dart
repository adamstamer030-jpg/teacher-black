/// كل موديلات البيانات بالتطبيق في ملف واحد (نفس أسلوب التطبيق المرجعي)
/// كل موديل يحتوي على fromMap/toMap للتعامل المباشر مع SQLite.

class Grade {
  final int? id;
  final String name;
  final int sortOrder;
  final String createdAt;

  Grade({
    this.id,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Grade.fromMap(Map<String, dynamic> m) => Grade(
        id: m['id'] as int?,
        name: m['name'] as String,
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  Grade copyWith({int? id, String? name, int? sortOrder}) => Grade(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}

class StudyGroup {
  final int? id;
  final int gradeId;
  final String name;
  final String color;
  final String? notes;
  final double monthlyFee;
  final int sortOrder;
  final String createdAt;

  StudyGroup({
    this.id,
    required this.gradeId,
    required this.name,
    this.color = '#6366F1',
    this.notes,
    this.monthlyFee = 0,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory StudyGroup.fromMap(Map<String, dynamic> m) => StudyGroup(
        id: m['id'] as int?,
        gradeId: m['grade_id'] as int,
        name: m['name'] as String,
        color: m['color'] as String? ?? '#6366F1',
        notes: m['notes'] as String?,
        monthlyFee: (m['monthly_fee'] as num?)?.toDouble() ?? 0,
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'grade_id': gradeId,
        'name': name,
        'color': color,
        'notes': notes,
        'monthly_fee': monthlyFee,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  StudyGroup copyWith({
    int? id,
    int? gradeId,
    String? name,
    String? color,
    String? notes,
    double? monthlyFee,
  }) =>
      StudyGroup(
        id: id ?? this.id,
        gradeId: gradeId ?? this.gradeId,
        name: name ?? this.name,
        color: color ?? this.color,
        notes: notes ?? this.notes,
        monthlyFee: monthlyFee ?? this.monthlyFee,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );
}

class GroupSchedule {
  final int? id;
  final int groupId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String? location;
  final String? notes;
  final String createdAt;

  GroupSchedule({
    this.id,
    required this.groupId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.notes,
    required this.createdAt,
  });

  factory GroupSchedule.fromMap(Map<String, dynamic> m) => GroupSchedule(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        dayOfWeek: m['day_of_week'] as String,
        startTime: m['start_time'] as String,
        endTime: m['end_time'] as String,
        location: m['location'] as String?,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'notes': notes,
        'created_at': createdAt,
      };
}

class ExtraFeeTemplate {
  final int? id;
  final int groupId;
  final String name;
  final double price;
  final String createdAt;

  ExtraFeeTemplate({
    this.id,
    required this.groupId,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  factory ExtraFeeTemplate.fromMap(Map<String, dynamic> m) => ExtraFeeTemplate(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        name: m['name'] as String,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'name': name,
        'price': price,
        'created_at': createdAt,
      };
}

class Student {
  final int? id;
  final String code;
  final String name;
  final String? phone;
  final String? parentPhone;
  final String? address;
  final String? school;
  final int? gradeId;
  final int? groupId;
  final String? gender;
  final String? birthDate;
  final String? notes;
  final String? photoPath;
  final String subscriptionDate;
  final String status;
  final int sortOrder;
  final bool isArchived;
  final String createdAt;

  Student({
    this.id,
    required this.code,
    required this.name,
    this.phone,
    this.parentPhone,
    this.address,
    this.school,
    this.gradeId,
    this.groupId,
    this.gender,
    this.birthDate,
    this.notes,
    this.photoPath,
    required this.subscriptionDate,
    this.status = 'نشط',
    this.sortOrder = 0,
    this.isArchived = false,
    required this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as int?,
        code: m['code'] as String,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        parentPhone: m['parent_phone'] as String?,
        address: m['address'] as String?,
        school: m['school'] as String?,
        gradeId: m['grade_id'] as int?,
        groupId: m['group_id'] as int?,
        gender: m['gender'] as String?,
        birthDate: m['birth_date'] as String?,
        notes: m['notes'] as String?,
        photoPath: m['photo_path'] as String?,
        subscriptionDate: m['subscription_date'] as String,
        status: m['status'] as String? ?? 'نشط',
        sortOrder: m['sort_order'] as int? ?? 0,
        isArchived: (m['is_archived'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'parent_phone': parentPhone,
        'address': address,
        'school': school,
        'grade_id': gradeId,
        'group_id': groupId,
        'gender': gender,
        'birth_date': birthDate,
        'notes': notes,
        'photo_path': photoPath,
        'subscription_date': subscriptionDate,
        'status': status,
        'sort_order': sortOrder,
        'is_archived': isArchived ? 1 : 0,
        'created_at': createdAt,
      };

  Student copyWith({
    String? code,
    String? name,
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
    String? subscriptionDate,
    String? status,
    int? sortOrder,
    bool? isArchived,
  }) =>
      Student(
        id: id,
        code: code ?? this.code,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        parentPhone: parentPhone ?? this.parentPhone,
        address: address ?? this.address,
        school: school ?? this.school,
        gradeId: gradeId ?? this.gradeId,
        groupId: groupId ?? this.groupId,
        gender: gender ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        notes: notes ?? this.notes,
        photoPath: photoPath ?? this.photoPath,
        subscriptionDate: subscriptionDate ?? this.subscriptionDate,
        status: status ?? this.status,
        sortOrder: sortOrder ?? this.sortOrder,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
      );
}

class StudentNote {
  final int? id;
  final int studentId;
  final String text;
  final String date;
  final String createdAt;

  StudentNote({
    this.id,
    required this.studentId,
    required this.text,
    required this.date,
    required this.createdAt,
  });

  factory StudentNote.fromMap(Map<String, dynamic> m) => StudentNote(
        id: m['id'] as int?,
        studentId: m['student_id'] as int,
        text: m['text'] as String,
        date: m['date'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'text': text,
        'date': date,
        'created_at': createdAt,
      };
}

class AttendanceRecord {
  final int? id;
  final int groupId;
  final int studentId;
  final String date;
  final String status;
  final String createdAt;

  AttendanceRecord({
    this.id,
    required this.groupId,
    required this.studentId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> m) => AttendanceRecord(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        studentId: m['student_id'] as int,
        date: m['date'] as String,
        status: m['status'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'student_id': studentId,
        'date': date,
        'status': status,
        'created_at': createdAt,
      };
}

class Exam {
  final int? id;
  final int groupId;
  final String name;
  final String date;
  final String? curriculum;
  final double maxScore;
  final String? notes;
  final String createdAt;

  Exam({
    this.id,
    required this.groupId,
    required this.name,
    required this.date,
    this.curriculum,
    this.maxScore = 100,
    this.notes,
    required this.createdAt,
  });

  factory Exam.fromMap(Map<String, dynamic> m) => Exam(
        id: m['id'] as int?,
        groupId: m['group_id'] as int,
        name: m['name'] as String,
        date: m['date'] as String,
        curriculum: m['curriculum'] as String?,
        maxScore: (m['max_score'] as num?)?.toDouble() ?? 100,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'group_id': groupId,
        'name': name,
        'date': date,
        'curriculum': curriculum,
        'max_score': maxScore,
        'notes': notes,
        'created_at': createdAt,
      };
}

class ExamResult {
  final int? id;
  final int examId;
  final int studentId;
  final double? score;
  final String? notes;
  final String createdAt;

  ExamResult({
    this.id,
    required this.examId,
    required this.studentId,
    this.score,
    this.notes,
    required this.createdAt,
  });

  factory ExamResult.fromMap(Map<String, dynamic> m) => ExamResult(
        id: m['id'] as int?,
        examId: m['exam_id'] as int,
        studentId: m['student_id'] as int,
        score: (m['score'] as num?)?.toDouble(),
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exam_id': examId,
        'student_id': studentId,
        'score': score,
        'notes': notes,
        'created_at': createdAt,
      };
}

class ExamAttachment {
  final int? id;
  final int examResultId;
  final String filePath;
  final String createdAt;

  ExamAttachment({
    this.id,
    required this.examResultId,
    required this.filePath,
    required this.createdAt,
  });

  factory ExamAttachment.fromMap(Map<String, dynamic> m) => ExamAttachment(
        id: m['id'] as int?,
        examResultId: m['exam_result_id'] as int,
        filePath: m['file_path'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exam_result_id': examResultId,
        'file_path': filePath,
        'created_at': createdAt,
      };
}

class StudentExtraFee {
  final int? id;
  final int studentId;
  final int? extraFeeId;
  final String name;
  final double price;
  final bool isPaid;
  final String createdAt;

  StudentExtraFee({
    this.id,
    required this.studentId,
    this.extraFeeId,
    required this.name,
    required this.price,
    this.isPaid = false,
    required this.createdAt,
  });

  factory StudentExtraFee.fromMap(Map<String, dynamic> m) => StudentExtraFee(
        id: m['id'] as int?,
        studentId: m['student_id'] as int,
        extraFeeId: m['extra_fee_id'] as int?,
        name: m['name'] as String,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        isPaid: (m['is_paid'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'extra_fee_id': extraFeeId,
        'name': name,
        'price': price,
        'is_paid': isPaid ? 1 : 0,
        'created_at': createdAt,
      };
}

class Payment {
  final int? id;
  final int studentId;
  final int? groupId;
  final String type; // اشتراك / رسوم إضافية / خصم
  final String title;
  final double dueAmount;
  final double amount;
  final String? monthYear;
  final int? studentExtraFeeId;
  final String? note;
  final String paymentDate;
  final String createdAt;

  Payment({
    this.id,
    required this.studentId,
    this.groupId,
    required this.type,
    required this.title,
    this.dueAmount = 0,
    required this.amount,
    this.monthYear,
    this.studentExtraFeeId,
    this.note,
    required this.paymentDate,
    required this.createdAt,
  });

  double get remaining => (dueAmount - amount) < 0 ? 0 : (dueAmount - amount);

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as int?,
        studentId: m['student_id'] as int,
        groupId: m['group_id'] as int?,
        type: m['type'] as String,
        title: m['title'] as String,
        dueAmount: (m['due_amount'] as num?)?.toDouble() ?? 0,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        monthYear: m['month_year'] as String?,
        studentExtraFeeId: m['student_extra_fee_id'] as int?,
        note: m['note'] as String?,
        paymentDate: m['payment_date'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_id': studentId,
        'group_id': groupId,
        'type': type,
        'title': title,
        'due_amount': dueAmount,
        'amount': amount,
        'month_year': monthYear,
        'student_extra_fee_id': studentExtraFeeId,
        'note': note,
        'payment_date': paymentDate,
        'created_at': createdAt,
      };
}

class Reservation {
  final int? id;
  final String studentName;
  final String? phone;
  final String? parentPhone;
  final int? gradeId;
  final String? studySystem;
  final String? term;
  final String status;
  final String? notes;
  final String createdAt;

  Reservation({
    this.id,
    required this.studentName,
    this.phone,
    this.parentPhone,
    this.gradeId,
    this.studySystem,
    this.term,
    this.status = 'جديد',
    this.notes,
    required this.createdAt,
  });

  factory Reservation.fromMap(Map<String, dynamic> m) => Reservation(
        id: m['id'] as int?,
        studentName: m['student_name'] as String,
        phone: m['phone'] as String?,
        parentPhone: m['parent_phone'] as String?,
        gradeId: m['grade_id'] as int?,
        studySystem: m['study_system'] as String?,
        term: m['term'] as String?,
        status: m['status'] as String? ?? 'جديد',
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'student_name': studentName,
        'phone': phone,
        'parent_phone': parentPhone,
        'grade_id': gradeId,
        'study_system': studySystem,
        'term': term,
        'status': status,
        'notes': notes,
        'created_at': createdAt,
      };

  Reservation copyWith({String? status}) => Reservation(
        id: id,
        studentName: studentName,
        phone: phone,
        parentPhone: parentPhone,
        gradeId: gradeId,
        studySystem: studySystem,
        term: term,
        status: status ?? this.status,
        notes: notes,
        createdAt: createdAt,
      );
}

class GeneralNote {
  final int? id;
  final String text;
  final String date;
  final String createdAt;

  GeneralNote({
    this.id,
    required this.text,
    required this.date,
    required this.createdAt,
  });

  factory GeneralNote.fromMap(Map<String, dynamic> m) => GeneralNote(
        id: m['id'] as int?,
        text: m['text'] as String,
        date: m['date'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'text': text,
        'date': date,
        'created_at': createdAt,
      };
}
