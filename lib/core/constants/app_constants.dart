/// قيم ثابتة مستخدمة في أكثر من شاشة بالتطبيق

class AppConstants {
  AppConstants._();

  static const String appName = 'منظم الدروس';

  // حالات الطالب
  static const List<String> studentStatuses = [
    'نشط',
    'متوقف مؤقتًا',
    'منسحب',
    'مؤجل',
    'متخرج',
  ];

  // حالات الحضور
  static const List<String> attendanceStatuses = [
    'حاضر',
    'غائب',
    'متأخر',
    'بإذن',
  ];

  // النوع
  static const List<String> genders = ['ذكر', 'أنثى'];

  // نظام الدراسة (للحجوزات)
  static const List<String> studySystems = ['عام', 'أزهري', 'بكالوريا'];

  // حالة الحجز
  static const List<String> reservationStatuses = [
    'جديد',
    'تم التواصل',
    'تم التسجيل',
    'ملغي',
  ];

  // نوع الترم في الحجز
  static const List<String> reservationTerms = [
    'حجز الفصل الدراسي الأول',
    'حجز الفصل الدراسي الثاني',
  ];

  // طرق ترتيب الطلاب
  static const List<String> studentSortOptions = [
    'تاريخ الاشتراك (الأقدم أولاً)',
    'الاسم',
    'الكود',
    'آخر عملية دفع',
    'ترتيب يدوي',
  ];

  // أيام الأسبوع
  static const List<String> weekDays = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
}
