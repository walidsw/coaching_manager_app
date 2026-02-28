import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coaching_center.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Students Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unique_student_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        father_name TEXT,
        mother_name TEXT,
        father_mobile TEXT,
        alternative_mobile TEXT,
        current_class TEXT NOT NULL,
        section TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Classes Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Classes (
        class_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT UNIQUE NOT NULL,
        monthly_fee REAL NOT NULL DEFAULT 0.0
      )
    ''');

    // 3. Exams Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Exams (
        exam_id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_name TEXT NOT NULL,
        exam_name TEXT NOT NULL,
        total_marks REAL NOT NULL,
        exam_date TEXT NOT NULL
      )
    ''');

    // 4. Marks Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Marks (
        mark_id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_unique_id TEXT NOT NULL,
        exam_id INTEGER NOT NULL,
        obtained_marks REAL NOT NULL,
        FOREIGN KEY(student_unique_id) REFERENCES Students(unique_student_id) ON DELETE CASCADE,
        FOREIGN KEY(exam_id) REFERENCES Exams(exam_id) ON DELETE CASCADE
      )
    ''');

    // 5. Payments Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_unique_id TEXT NOT NULL,
        class_name TEXT NOT NULL,
        month TEXT NOT NULL,
        year TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_status TEXT DEFAULT 'unpaid',
        FOREIGN KEY(student_unique_id) REFERENCES Students(unique_student_id) ON DELETE CASCADE
      )
    ''');

    // 6. PromotionHistory Table (fixed column names to match Python insert)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS PromotionHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_unique_id TEXT,
        year TEXT,
        old_class TEXT,
        new_class TEXT,
        overall_result_summary TEXT,
        FOREIGN KEY (student_unique_id) REFERENCES Students(unique_student_id) ON DELETE CASCADE
      )
    ''');

    // 7. AppConfig Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS AppConfig (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Seed default classes
    List<Map<String, dynamic>> defaultClasses = [
      {'class_name': 'Class 3', 'monthly_fee': 500.0},
      {'class_name': 'Class 4', 'monthly_fee': 500.0},
      {'class_name': 'Class 5', 'monthly_fee': 500.0},
      {'class_name': 'Class 6', 'monthly_fee': 500.0},
      {'class_name': 'Class 7', 'monthly_fee': 500.0},
      {'class_name': 'Class 8', 'monthly_fee': 500.0},
      {'class_name': 'Class 9', 'monthly_fee': 500.0},
      {'class_name': 'Class 10', 'monthly_fee': 500.0},
    ];

    for (var classData in defaultClasses) {
      await db.insert('Classes', classData);
    }

    // Seed default admin password
    await db.insert('AppConfig', {'key': 'admin_password', 'value': 'admin'});

    // 8. Teachers Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Teachers (
        teacher_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        subject TEXT,
        phone TEXT,
        monthly_salary REAL NOT NULL DEFAULT 0.0,
        status TEXT DEFAULT 'active'
      )
    ''');

    // 9. TeacherSalary Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS TeacherSalary (
        salary_id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL,
        month TEXT NOT NULL,
        year TEXT NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0.0,
        paid_status TEXT DEFAULT 'unpaid',
        FOREIGN KEY(teacher_id) REFERENCES Teachers(teacher_id) ON DELETE CASCADE
      )
    ''');

    // 10. Costs Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Costs (
        cost_id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        year TEXT NOT NULL,
        note TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Teachers (
          teacher_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          subject TEXT,
          phone TEXT,
          monthly_salary REAL NOT NULL DEFAULT 0.0,
          status TEXT DEFAULT 'active'
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS TeacherSalary (
          salary_id INTEGER PRIMARY KEY AUTOINCREMENT,
          teacher_id INTEGER NOT NULL,
          month TEXT NOT NULL,
          year TEXT NOT NULL,
          amount_paid REAL NOT NULL DEFAULT 0.0,
          paid_status TEXT DEFAULT 'unpaid',
          FOREIGN KEY(teacher_id) REFERENCES Teachers(teacher_id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Costs (
          cost_id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          month TEXT NOT NULL,
          year TEXT NOT NULL,
          note TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE Students ADD COLUMN created_at TEXT DEFAULT '2026-02-01 00:00:00'");
    }
  }

  // --- Admin Operations ---
  Future<bool> verifyAdmin(String password) async {
    final db = await instance.database;
    final result = await db.query(
      'AppConfig',
      where: 'key = ?',
      whereArgs: ['admin_password'],
    );
    if (result.isNotEmpty) {
      return result.first['value'] == password;
    }
    return false;
  }

  Future<void> updateAdminPassword(String newPassword) async {
    final db = await instance.database;
    await db.update(
      'AppConfig',
      {'value': newPassword},
      where: 'key = ?',
      whereArgs: ['admin_password'],
    );
  }

  // --- Student Operations ---
  Future<String> generateStudentId() async {
    final db = await instance.database;
    final result = await db.query('Students', orderBy: 'id DESC', limit: 1);
    int nextId = 1;
    if (result.isNotEmpty) {
      nextId = (result.first['id'] as int) + 1;
    }
    return 'STU${nextId.toString().padLeft(4, '0')}';
  }

  Future<String> addStudent(Map<String, dynamic> studentData) async {
    final db = await instance.database;
    final String studentId = await generateStudentId();
    studentData['unique_student_id'] = studentId;
    await db.insert('Students', studentData);
    return studentId;
  }

  Future<List<Map<String, dynamic>>> getStudentsByClass(String className) async {
    final db = await instance.database;
    return await db.query('Students',
        where: 'current_class = ? AND status = ?',
        whereArgs: [className, 'active']);
  }

  Future<Map<String, dynamic>?> getStudentById(String studentUniqueId) async {
    final db = await instance.database;
    final result = await db.query('Students',
        where: 'unique_student_id = ?', whereArgs: [studentUniqueId]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateStudent(String studentUniqueId, Map<String, dynamic> studentData) async {
    final db = await instance.database;
    await db.update('Students', studentData,
        where: 'unique_student_id = ?', whereArgs: [studentUniqueId]);
  }

  Future<void> deleteStudent(String studentUniqueId) async {
    final db = await instance.database;
    await db.delete('Students',
        where: 'unique_student_id = ?', whereArgs: [studentUniqueId]);
  }

  // --- Class Operations ---
  Future<List<Map<String, dynamic>>> getClasses() async {
    final db = await instance.database;
    return await db.query('Classes');
  }

  Future<double> getClassFee(String className) async {
    final db = await instance.database;
    final result = await db.query('Classes',
        columns: ['monthly_fee'],
        where: 'class_name = ?',
        whereArgs: [className]);
    if (result.isNotEmpty) {
      return (result.first['monthly_fee'] as num).toDouble();
    }
    return 0.0;
  }

  Future<void> updateClassFee(String className, double fee) async {
    final db = await instance.database;
    await db.update('Classes', {'monthly_fee': fee},
        where: 'class_name = ?', whereArgs: [className]);
  }

  // --- Exam Operations ---
  Future<int> addExam(Map<String, dynamic> examData) async {
    final db = await instance.database;
    return await db.insert('Exams', examData);
  }

  Future<List<Map<String, dynamic>>> getExamsByClass(String className) async {
    final db = await instance.database;
    return await db.query('Exams', where: 'class_name = ?', whereArgs: [className]);
  }

  Future<void> deleteExam(int examId) async {
    final db = await instance.database;
    await db.delete('Exams', where: 'exam_id = ?', whereArgs: [examId]);
  }

  // --- Marks Operations ---
  Future<void> addOrUpdateMark(String studentUniqueId, int examId, double obtainedMarks) async {
    final db = await instance.database;
    final result = await db.query('Marks',
        where: 'student_unique_id = ? AND exam_id = ?',
        whereArgs: [studentUniqueId, examId]);

    if (result.isNotEmpty) {
      int markId = result.first['mark_id'] as int;
      await db.update('Marks', {'obtained_marks': obtainedMarks},
          where: 'mark_id = ?', whereArgs: [markId]);
    } else {
      await db.insert('Marks', {
        'student_unique_id': studentUniqueId,
        'exam_id': examId,
        'obtained_marks': obtainedMarks
      });
    }
  }

  Future<List<Map<String, dynamic>>> getMarksForStudent(String studentUniqueId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT e.exam_name, e.total_marks, m.obtained_marks, e.exam_date, e.class_name
      FROM Marks m
      JOIN Exams e ON m.exam_id = e.exam_id
      WHERE m.student_unique_id = ?
    ''', [studentUniqueId]);
  }

  Future<List<Map<String, dynamic>>> getMarksByExam(int examId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT s.unique_student_id, s.name, m.obtained_marks 
      FROM Students s
      LEFT JOIN Marks m ON s.unique_student_id = m.student_unique_id AND m.exam_id = ?
      WHERE s.current_class = (SELECT class_name FROM Exams WHERE exam_id = ?)
      AND s.status = 'active'
    ''', [examId, examId]);
  }

  Future<double> getHighestMarksForExam(int examId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT MAX(obtained_marks) as max_marks FROM Marks WHERE exam_id = ?', [examId]);
    if (result.isNotEmpty && result.first['max_marks'] != null) {
      return (result.first['max_marks'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getAverageMarksForExam(int examId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT AVG(obtained_marks) as avg_marks FROM Marks WHERE exam_id = ?', [examId]);
    if (result.isNotEmpty && result.first['avg_marks'] != null) {
      return (result.first['avg_marks'] as num).toDouble();
    }
    return 0.0;
  }

  Future<Map<String, int>> getStudentExamStats(String studentUniqueId, String className) async {
    final db = await instance.database;
    
    final totalExamsResult = await db.rawQuery('SELECT COUNT(*) as count FROM Exams WHERE class_name = ?', [className]);
    int totalExams = totalExamsResult.first['count'] as int;
    
    final attendedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM Marks m 
      JOIN Exams e ON m.exam_id = e.exam_id 
      WHERE m.student_unique_id = ? AND e.class_name = ?
    ''', [studentUniqueId, className]);
    
    int attended = attendedResult.first['count'] as int;
    int missed = totalExams - attended;
    
    return {
      'total': totalExams,
      'attended': attended,
      'missed': missed,
    };
  }

  // --- Payment Operations ---
  Future<List<Map<String, dynamic>>> getPaymentsForStudent(String studentUniqueId) async {
    final db = await instance.database;
    return await db.query('Payments',
        where: 'student_unique_id = ?',
        whereArgs: [studentUniqueId],
        orderBy: 'year DESC, month DESC');
  }

  Future<void> addPayment(String studentUniqueId, String className, String month, String year, double amount, {String paidStatus = 'paid'}) async {
    final db = await instance.database;
    final result = await db.query('Payments',
        where: 'student_unique_id = ? AND month = ? AND year = ?',
        whereArgs: [studentUniqueId, month, year]);

    if (result.isNotEmpty) {
      int paymentId = result.first['payment_id'] as int;
      await db.update('Payments', {'paid_status': paidStatus, 'amount': amount},
          where: 'payment_id = ?', whereArgs: [paymentId]);
    } else {
      await db.insert('Payments', {
        'student_unique_id': studentUniqueId,
        'class_name': className,
        'month': month,
        'year': year,
        'amount': amount,
        'paid_status': paidStatus
      });
    }
  }

  // --- Promotion Operations ---
  Future<void> promoteStudent(String studentUniqueId, String newClass, {String overallSummary = ""}) async {
    final db = await instance.database;
    final result = await db.query('Students', columns: ['current_class'], where: 'unique_student_id = ?', whereArgs: [studentUniqueId]);
    
    if (result.isEmpty) return;
    
    String oldClass = result.first['current_class'] as String;
    String currentYear = DateTime.now().year.toString();
    
    await db.insert('PromotionHistory', {
      'student_unique_id': studentUniqueId,
      'old_class': oldClass,
      'new_class': newClass,
      'year': currentYear,
      'overall_result_summary': overallSummary
    });
    
    await db.update('Students', {'current_class': newClass}, where: 'unique_student_id = ?', whereArgs: [studentUniqueId]);
  }

  Future<List<Map<String, dynamic>>> getPromotionHistory(String studentUniqueId) async {
    final db = await instance.database;
    return await db.query('PromotionHistory', where: 'student_unique_id = ?', whereArgs: [studentUniqueId], orderBy: 'year DESC');
  }

  // --- Reporting Operations ---
  Future<int> getTotalStudents() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM Students WHERE status = 'active'");
    return result.first['count'] as int;
  }

  Future<int> getTotalBatches() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM Classes");
    return result.first['count'] as int;
  }

  Future<int> getTotalExams() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM Exams");
    return result.first['count'] as int;
  }

  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM Payments WHERE paid_status = 'paid'");
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Returns the total amount still owed by ALL active students for the current month.
  /// Formula: SUM(class monthly fee) for every active student  −  SUM(amount paid this month)
  Future<double> getTotalDueThisMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    final List<String> months = ["January","February","March","April","May","June",
      "July","August","September","October","November","December"];
    final String month = months[now.month - 1];
    final String year = now.year.toString();

    // Total fees owed = sum of each active student's class fee
    final feeResult = await db.rawQuery('''
      SELECT SUM(c.monthly_fee) as total
      FROM Students s
      JOIN Classes c ON c.class_name = s.current_class
      WHERE s.status = 'active'
    ''');
    final double totalFee = (feeResult.isNotEmpty && feeResult.first['total'] != null)
        ? (feeResult.first['total'] as num).toDouble()
        : 0.0;

    // Total already paid this month
    final paidResult = await db.rawQuery(
      "SELECT SUM(amount) as paid FROM Payments WHERE month = ? AND year = ?",
      [month, year],
    );
    final double paid = (paidResult.isNotEmpty && paidResult.first['paid'] != null)
        ? (paidResult.first['paid'] as num).toDouble()
        : 0.0;

    final double due = totalFee - paid;
    return due > 0 ? due : 0.0;
  }

  Future<int> getTotalPayments() async {
    final db = await instance.database;
    String currentYear = DateTime.now().year.toString();
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM Payments WHERE year = ? AND paid_status = 'paid'", [currentYear]);
    return result.first['count'] as int;
  }

  // ─── Monthly Analytics ──────────────────────────────────────

  Future<double> getTotalEarnedThisMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    final List<String> months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    final month = months[now.month - 1];
    final year = now.year.toString();
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM Payments WHERE month = ? AND year = ? AND paid_status = 'paid'", [month, year]);
    return (result.isNotEmpty && result.first['total'] != null) ? (result.first['total'] as num).toDouble() : 0.0;
  }

  Future<double> getTotalTutorFeeThisMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    final List<String> months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    final month = months[now.month - 1];
    final year = now.year.toString();
    final result = await db.rawQuery("SELECT SUM(amount_paid) as total FROM TeacherSalary WHERE month = ? AND year = ?", [month, year]);
    return (result.isNotEmpty && result.first['total'] != null) ? (result.first['total'] as num).toDouble() : 0.0;
  }

  Future<double> getTotalCostThisMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    final List<String> months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    final month = months[now.month - 1];
    final year = now.year.toString();
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM Costs WHERE month = ? AND year = ?", [month, year]);
    return (result.isNotEmpty && result.first['total'] != null) ? (result.first['total'] as num).toDouble() : 0.0;
  }

  Future<double> getNetRevenueThisMonth() async {
    final earned = await getTotalEarnedThisMonth();
    final tutorFee = await getTotalTutorFeeThisMonth();
    final cost = await getTotalCostThisMonth();
    return earned - tutorFee - cost;
  }

  Future<int> getNewStudentsThisMonth() async {
    final db = await instance.database;
    // SQLite CURRENT_TIMESTAMP is in UTC '%Y-%m-%d %H:%M:%S'
    // We compare strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')
    // To handle local time accurately without complex sqlite datetime config:
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    final query = "SELECT COUNT(*) as count FROM Students WHERE created_at LIKE '${now.year}-$monthStr-%'";
    final result = await db.rawQuery(query);
    return result.first['count'] as int;
  }

  // ─── Teacher Operations ──────────────────────────────────
  Future<int> addTeacher(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('Teachers', data);
  }

  Future<List<Map<String, dynamic>>> getTeachers({bool activeOnly = true}) async {
    final db = await instance.database;
    if (activeOnly) {
      return await db.query('Teachers', where: 'status = ?', whereArgs: ['active'], orderBy: 'name ASC');
    }
    return await db.query('Teachers', orderBy: 'name ASC');
  }

  Future<void> updateTeacher(int teacherId, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('Teachers', data, where: 'teacher_id = ?', whereArgs: [teacherId]);
  }

  Future<void> deleteTeacher(int teacherId) async {
    final db = await instance.database;
    await db.update('Teachers', {'status': 'inactive'}, where: 'teacher_id = ?', whereArgs: [teacherId]);
  }

  Future<Map<String, dynamic>?> getSalaryRecord(int teacherId, String month, String year) async {
    final db = await instance.database;
    final result = await db.query(
      'TeacherSalary',
      where: 'teacher_id = ? AND month = ? AND year = ?',
      whereArgs: [teacherId, month, year],
    );
    return result.isNotEmpty ? Map<String, dynamic>.from(result.first) : null;
  }

  Future<void> upsertSalaryPayment(int teacherId, String month, String year, double amountPaid, String status) async {
    final db = await instance.database;
    final existing = await getSalaryRecord(teacherId, month, year);
    if (existing == null) {
      await db.insert('TeacherSalary', {
        'teacher_id': teacherId, 'month': month, 'year': year,
        'amount_paid': amountPaid, 'paid_status': status,
      });
    } else {
      await db.update('TeacherSalary',
        {'amount_paid': amountPaid, 'paid_status': status},
        where: 'teacher_id = ? AND month = ? AND year = ?',
        whereArgs: [teacherId, month, year],
      );
    }
  }

  // ─── Cost Operations ─────────────────────────────────────
  Future<int> addCost(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('Costs', data);
  }

  Future<List<Map<String, dynamic>>> getCostsByMonth(String month, String year) async {
    final db = await instance.database;
    return await db.query('Costs',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      orderBy: 'category ASC, cost_id ASC',
    );
  }

  Future<void> updateCost(int costId, Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.update('Costs', data, where: 'cost_id = ?', whereArgs: [costId]);
  }

  Future<void> deleteCost(int costId) async {
    final db = await instance.database;
    await db.delete('Costs', where: 'cost_id = ?', whereArgs: [costId]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  /// Deletes the entire database file and recreates it fresh.
  /// All data is permanently lost. The singleton cache is cleared first.
  Future<void> resetDatabase() async {
    // Close and discard cached instance
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    // Delete the physical file
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'coaching_center.db');
    await deleteDatabase(path);
    // Reinitialise — onCreate will run, seeding default data
    _database = await _initDB('coaching_center.db');
  }
}
