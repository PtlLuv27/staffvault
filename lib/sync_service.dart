import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> syncDataAndGenerateReport() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch all local employee data from SQLite
      List<Map<String, dynamic>> employees = await _dbHelper.queryAllEmployees();

      // 2. Use a Batch to upload everything at once for efficiency
      WriteBatch batch = _firestore.batch();

      for (var emp in employees) {
        // Create a reference path: users -> [UID] -> employees -> [EmployeeID]
        DocumentReference empRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('employees')
            .doc(emp['id'].toString());

        batch.set(empRef, emp);

        // Optional: Fetch and sync attendance logs for this employee
        List<Map<String, dynamic>> attendanceLogs = await _dbHelper.getAttendanceForEmployee(emp['id']);
        for (var log in attendanceLogs) {
          DocumentReference attRef = empRef.collection('attendance').doc(log['id'].toString());
          batch.set(attRef, log);
        }
      }

      // 3. Commit the batch to the cloud
      await batch.commit();
      print("Sync successful!");
    } catch (e) {
      print("Sync failed: $e");
      rethrow;
    }
  }
}