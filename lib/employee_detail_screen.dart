import 'package:flutter/material.dart';
import 'database_helper.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  List<Map<String, dynamic>> _history = [];
  double _totalNetSalary = 0.0;
  String? _selectedMonth; // Stores the YYYY-MM filter

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Feature 1: Load filtered or lifetime history
  void _loadHistory() async {
    List<Map<String, dynamic>> data;
    if (_selectedMonth == null) {
      data = await DatabaseHelper.instance.getAttendanceForEmployee(widget.employee['id']);
    } else {
      data = await DatabaseHelper.instance.getAttendanceForMonth(widget.employee['id'], _selectedMonth!);
    }

    double runningNet = 0.0;
    for (var log in data) {
      // Calculate earnings based on status
      double earned = _calculateDailyEarned(log['status'] ?? 'Absent');

      // Feature 4: Safe storage & display of financials
      double bonus = (log['bonus'] ?? 0.0).toDouble();
      double loan = (log['loan'] ?? 0.0).toDouble();

      runningNet += (earned + bonus - loan);
    }

    setState(() {
      _history = data;
      _totalNetSalary = runningNet;
    });
  }

  double _calculateDailyEarned(String status) {
    double base = widget.employee['salaryAmount'] ?? 0.0;
    double multiplier = status == 'Present' ? 1.0 : (status == 'Half-day' ? 0.5 : 0.0);
    return (widget.employee['salaryType'] == 'Monthly' ? base / 30 : base) * multiplier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.employee['name']}'s History"),
        actions: [
          // Feature 1: Interactive Month Filter
          IconButton(
            icon: Icon(_selectedMonth == null ? Icons.filter_alt_outlined : Icons.filter_alt),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2100),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedMonth = "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
                });
                _loadHistory();
              } else {
                setState(() => _selectedMonth = null); // Reset filter
                _loadHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blueAccent,
            width: double.infinity,
            child: Column(
              children: [
                Text(
                  _selectedMonth == null ? "Lifetime Net Balance" : "Net Salary for $_selectedMonth",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "₹${_totalNetSalary.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text("No records found for this period."))
                : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final log = _history[index];
                double bonus = (log['bonus'] ?? 0.0).toDouble();
                double loan = (log['loan'] ?? 0.0).toDouble();
                String note = log['note'] ?? "";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text("Date: ${log['date']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${log['status'] ?? 'Absent'}"),
                        if (bonus > 0) Text("Bonus: +₹$bonus", style: const TextStyle(color: Colors.green)),
                        if (loan > 0) Text("Loan: -₹$loan", style: const TextStyle(color: Colors.red)),
                        if (note.isNotEmpty) Text("Note: $note", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                      ],
                    ),
                    trailing: Icon(
                      log['status'] == 'Present' ? Icons.check_circle : Icons.cancel,
                      color: log['status'] == 'Present' ? Colors.green : Colors.red,
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
}