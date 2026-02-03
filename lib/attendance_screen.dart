import 'package:flutter/material.dart';
import 'database_helper.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _employees = [];
  DateTime _selectedDate = DateTime.now();
  // Tracks the current status of each employee for the selected date
  Map<int, String> _currentStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fetches employees and existing attendance for the selected date
  void _loadData() async {
    final empData = await DatabaseHelper.instance.queryAllEmployees();
    // Fetch all attendance records for the specific selected date
    final attendanceData = await DatabaseHelper.instance.getAttendanceForDate(_formattedDate);

    Map<int, String> statusMap = {};
    for (var record in attendanceData) {
      statusMap[record['employeeId']] = record['status'] ?? '';
    }

    setState(() {
      _employees = empData;
      _currentStatuses = statusMap;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
      _loadData(); // Refresh list for the new selected date
    }
  }

  String get _formattedDate => _selectedDate.toString().split(' ')[0];

  void _markAttendance(int empId, String status) async {
    await DatabaseHelper.instance.markAttendance({
      'employeeId': empId,
      'date': _formattedDate,
      'status': status,
    });
    setState(() {
      _currentStatuses[empId] = status; // Triggers the color reversal UI
    });
  }

  // Feature 2: Financial Adjustments Dialog
  void _showFinancialDialog(int empId, String empName) async {
    // 1. Fetch any existing record for this specific day to show previous values
    final existing = await DatabaseHelper.instance.getSingleAttendance(empId, _formattedDate);

    // 2. Pre-fill the controllers with previous values if they exist, else leave empty
    final bonusController = TextEditingController(
        text: existing != null && (existing['bonus'] ?? 0) > 0
            ? existing['bonus'].toString()
            : ""
    );
    final loanController = TextEditingController(
        text: existing != null && (existing['loan'] ?? 0) > 0
            ? existing['loan'].toString()
            : ""
    );
    final noteController = TextEditingController(
        text: existing?['note'] ?? ""
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Adjustments for $empName"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: bonusController,
                  decoration: const InputDecoration(labelText: "Bonus / Profit", prefixText: "₹"),
                  keyboardType: TextInputType.number
              ),
              TextField(
                  controller: loanController,
                  decoration: const InputDecoration(labelText: "Loan / Advance", prefixText: "₹"),
                  keyboardType: TextInputType.number
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: "Note (Reason)"),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              // 3. Save the new values - DatabaseHelper handles merging with existing status
              await DatabaseHelper.instance.markAttendance({
                'employeeId': empId,
                'date': _formattedDate,
                'bonus': double.tryParse(bonusController.text) ?? 0.0,
                'loan': double.tryParse(loanController.text) ?? 0.0,
                'note': noteController.text,
              });

              if (mounted) {
                Navigator.pop(context); // Requirement: Close the menu

                // Requirement: Display "Adjustments Applied" message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Adjustments Applied"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Attendance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.withOpacity(0.1),
            child: Center(
              child: Text(
                "Selected Date: $_formattedDate",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(emp['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          _statusButton(emp['id'], 'Present', Colors.green),
                          _statusButton(emp['id'], 'Absent', Colors.red),
                          _statusButton(emp['id'], 'Half-day', Colors.orange),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.currency_exchange, color: Colors.blue),
                      onPressed: () => _showFinancialDialog(emp['id'], emp['name']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Feature 3: Color-reversing Status Button logic
  Widget _statusButton(int empId, String status, Color color) {
    bool isSelected = _currentStatuses[empId] == status;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          // Solid background if active, white if not
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () => _markAttendance(empId, status),
        child: Text(status, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}