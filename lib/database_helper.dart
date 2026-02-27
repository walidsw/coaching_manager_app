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
      version: 1,
      onCreate: _createDB,
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
        status TEXT DEFAULT 'active'
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
    String currentYear = DateTime.now().year.toString();
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM Payments WHERE year = ? AND paid_status = 'paid'", [currentYear]);
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> getTotalPayments() async {
    final db = await instance.database;
    String currentYear = DateTime.now().year.toString();
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM Payments WHERE year = ? AND paid_status = 'paid'", [currentYear]);
    return result.first['count'] as int;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
