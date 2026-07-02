import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// طبقة الوصول لقاعدة بيانات SQLite المحلية.
/// التطبيق يعمل بالكامل Offline، وكل البيانات مخزّنة في ملف قاعدة بيانات
/// واحد قابل للنسخ الاحتياطي والاستعادة من شاشة الإعدادات.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const int dbVersion = 1;
  static const String dbFileName = 'tutor_manager.db';

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  /// مسار ملف قاعدة البيانات على الجهاز (يُستخدم في النسخ الاحتياطي)
  Future<String> get databasePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, dbFileName);
  }

  Future<Database> _open() async {
    final path = await databasePath;
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // تُضاف هنا أوامر ALTER عند رفع إصدار قاعدة البيانات مستقبلاً
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    // الصفوف الدراسية
    batch.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // المجموعات
    batch.execute('''
      CREATE TABLE groups_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grade_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#6366F1',
        notes TEXT,
        monthly_fee REAL NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (grade_id) REFERENCES grades (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_groups_grade ON groups_table (grade_id)');

    // مواعيد المجموعة (يمكن أن يكون لمجموعة أكثر من ميعاد بالأسبوع)
    batch.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        day_of_week TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_schedules_group ON schedules (group_id)');

    // قوالب الرسوم الإضافية لكل مجموعة
    batch.execute('''
      CREATE TABLE extra_fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_extra_fees_group ON extra_fees (group_id)');

    // الطلاب
    batch.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT,
        parent_phone TEXT,
        address TEXT,
        school TEXT,
        grade_id INTEGER,
        group_id INTEGER,
        gender TEXT,
        birth_date TEXT,
        notes TEXT,
        photo_path TEXT,
        subscription_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'نشط',
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (grade_id) REFERENCES grades (id) ON DELETE SET NULL,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE SET NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_students_group ON students (group_id)');
    batch.execute('CREATE INDEX idx_students_grade ON students (grade_id)');
    batch.execute('CREATE INDEX idx_students_phone ON students (phone)');
    batch.execute('CREATE INDEX idx_students_code ON students (code)');
    batch.execute('CREATE INDEX idx_students_name ON students (name)');

    // ملاحظات الطالب
    batch.execute('''
      CREATE TABLE student_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_student_notes_student ON student_notes (student_id)');

    // الحضور والغياب
    batch.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        UNIQUE (student_id, date)
      )
    ''');
    batch.execute('CREATE INDEX idx_attendance_group_date ON attendance (group_id, date)');
    batch.execute('CREATE INDEX idx_attendance_student ON attendance (student_id)');

    // الاختبارات
    batch.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        curriculum TEXT,
        max_score REAL NOT NULL DEFAULT 100,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_exams_group ON exams (group_id)');

    // نتائج الاختبارات
    batch.execute('''
      CREATE TABLE exam_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        score REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams (id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        UNIQUE (exam_id, student_id)
      )
    ''');
    batch.execute('CREATE INDEX idx_exam_results_exam ON exam_results (exam_id)');
    batch.execute('CREATE INDEX idx_exam_results_student ON exam_results (student_id)');

    // صور أوراق الامتحانات (مرفقات نتيجة الاختبار)
    batch.execute('''
      CREATE TABLE attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_result_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exam_result_id) REFERENCES exam_results (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_attachments_result ON attachments (exam_result_id)');

    // الرسوم الإضافية المخصصة لطالب معين
    batch.execute('''
      CREATE TABLE student_extra_fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        extra_fee_id INTEGER,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (extra_fee_id) REFERENCES extra_fees (id) ON DELETE SET NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_student_extra_fees_student ON student_extra_fees (student_id)');

    // المدفوعات
    batch.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        group_id INTEGER,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        due_amount REAL NOT NULL DEFAULT 0,
        amount REAL NOT NULL DEFAULT 0,
        month_year TEXT,
        student_extra_fee_id INTEGER,
        note TEXT,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups_table (id) ON DELETE SET NULL,
        FOREIGN KEY (student_extra_fee_id) REFERENCES student_extra_fees (id) ON DELETE SET NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_payments_student ON payments (student_id)');
    batch.execute('CREATE INDEX idx_payments_date ON payments (payment_date)');

    // الحجوزات
    batch.execute('''
      CREATE TABLE reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_name TEXT NOT NULL,
        phone TEXT,
        parent_phone TEXT,
        grade_id INTEGER,
        study_system TEXT,
        term TEXT,
        status TEXT NOT NULL DEFAULT 'جديد',
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (grade_id) REFERENCES grades (id) ON DELETE SET NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_reservations_status ON reservations (status)');

    // الملاحظات العامة (غير مرتبطة بطالب)
    batch.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // الإعدادات (key-value)
    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// إغلاق الاتصال (يُستخدم قبل عمليات النسخ الاحتياطي / الاستعادة)
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// إعادة فتح الاتصال بعد عملية الاستعادة
  Future<void> reopen() async {
    await close();
    _db = await _open();
  }
}
