import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //
import 'package:firebase_auth/firebase_auth.dart'; //

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('staffvault.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        joiningDate TEXT,
        salaryType TEXT,
        salaryAmount REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER,
        date TEXT,
        status TEXT,
        bonus REAL DEFAULT 0.0,
        loan REAL DEFAULT 0.0,
        note TEXT,
        FOREIGN KEY (employeeId) REFERENCES employees (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CLOUD SYNC LOGIC ---

  /// Pushes local SQLite data to Firebase Firestore
  Future<void> syncToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Only sync if logged in

    final firestore = FirebaseFirestore.instance;
    // Use the unified Firebase UID as the document ID
    final userDoc = firestore.collection('users').doc(user.uid);

    final employees = await queryAllEmployees();

    for (var emp in employees) {
      // Sync employee profile
      await userDoc.collection('employees').doc(emp['id'].toString()).set(emp);

      // Sync specific attendance logs for this employee
      final attendance = await getAttendanceForEmployee(emp['id']);
      for (var log in attendance) {
        await userDoc
            .collection('employees')
            .doc(emp['id'].toString())
            .collection('attendance')
            .doc(log['date'])
            .set(log);
      }
    }
  }

  // --- EMPLOYEE METHODS ---

  Future<int> insertEmployee(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = await db.insert('employees', row);
    syncToCloud(); // Trigger background sync
    return id;
  }

  Future<int> updateEmployee(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    int result = await db.update('employees', row, where: 'id = ?', whereArgs: [id]);
    syncToCloud(); // Trigger background sync
    return result;
  }

  Future<int> deleteEmployee(int id) async {
    final db = await instance.database;
    int result = await db.delete('employees', where: 'id = ?', whereArgs: [id]);
    // Note: Cloud deletion could also be handled here
    return result;
  }

  Future<List<Map<String, dynamic>>> queryAllEmployees() async {
    final db = await instance.database;
    return await db.query('employees');
  }

  // --- ATTENDANCE METHODS ---

  Future<int> markAttendance(Map<String, dynamic> row) async {
    final db = await instance.database;
    final existing = await db.query(
      'attendance',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [row['employeeId'], row['date']],
    );

    int result;
    if (existing.isNotEmpty) {
      // Merge logic: Ensures bonus/loan/note updates don't erase status
      Map<String, dynamic> updateData = Map.of(existing.first);
      updateData.addAll(row);
      result = await db.update('attendance', updateData, where: 'id = ?', whereArgs: [existing.first['id']]);
    } else {
      if (!row.containsKey('status')) row['status'] = 'Absent';
      result = await db.insert('attendance', row);
    }

    syncToCloud(); // Trigger background sync
    return result;
  }

  Future<Map<String, dynamic>?> getSingleAttendance(int empId, String date) async {
    final db = await instance.database;
    final results = await db.query(
      'attendance',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [empId, date],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAttendanceForDate(String date) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<Map<String, dynamic>>> getAttendanceForEmployee(int empId) async {
    final db = await instance.database;
    return await db.query('attendance', where: 'employeeId = ?', whereArgs: [empId], orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getAttendanceForMonth(int empId, String yearMonth) async {
    final db = await instance.database;
    return await db.query(
      'attendance',
      where: 'employeeId = ? AND date LIKE ?',
      whereArgs: [empId, '$yearMonth%'],
    );
  }
}