import 'package:flutter/material.dart';
import 'database_helper.dart';

class SalaryDashboardScreen extends StatefulWidget {
  const SalaryDashboardScreen({super.key});

  @override
  State<SalaryDashboardScreen> createState() => _SalaryDashboardScreenState();
}

class _SalaryDashboardScreenState extends State<SalaryDashboardScreen> {
  List<Map<String, dynamic>> _salaryData = [];
  double _totalCompanyPayout = 0.0;
  String _currentMonth = DateTime.now().toString().substring(0, 7);

  @override
  void initState() {
    super.initState();
    _calculateSalaries();
  }

  // Feature 2: Recalculate based on the month filter
  void _calculateSalaries() async {
    final employees = await DatabaseHelper.instance.queryAllEmployees();
    List<Map<String, dynamic>> computedList = [];
    double companyTotal = 0.0;

    for (var emp in employees) {
      final logs = await DatabaseHelper.instance.getAttendanceForMonth(emp['id'], _currentMonth);

      int present = logs.where((l) => l['status'] == 'Present').length;
      int halfDay = logs.where((l) => l['status'] == 'Half-day').length;
      int absent = logs.where((l) => l['status'] == 'Absent').length;

      double bonus = logs.fold(0.0, (sum, item) => sum + (item['bonus'] ?? 0.0));
      double loan = logs.fold(0.0, (sum, item) => sum + (item['loan'] ?? 0.0));

      double base = emp['salaryAmount'] ?? 0.0;
      double earned = (emp['salaryType'] == 'Monthly' ? base / 30 : base) * (present + (halfDay * 0.5));

      // Net salary logic: Green if positive, Red if negative
      double net = earned + bonus - loan;

      computedList.add({
        'name': emp['name'],
        'net': net,
        'bonus': bonus,
        'loan': loan,
        'stats': "P: $present | H: $halfDay | A: $absent"
      });
      companyTotal += net;
    }

    setState(() {
      _salaryData = computedList;
      _totalCompanyPayout = companyTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salary Dashboard"),
        actions: [
          // Feature 2: Month Filter
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _currentMonth = "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
                });
                _calculateSalaries();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade800,
            child: Column(
              children: [
                Text("Total Payout for $_currentMonth", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  "Rs. ${_totalCompanyPayout.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _salaryData.length,
              itemBuilder: (context, index) {
                final item = _salaryData[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['stats'], style: const TextStyle(color: Colors.blueGrey)),
                        Text("Bonus: +Rs. ${item['bonus']} | Loan: -Rs. ${item['loan']}", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Text(
                      "Rs. ${item['net'].toStringAsFixed(2)}",
                      style: TextStyle(
                        color: item['net'] < 0 ? Colors.red : Colors.green, // Visual status
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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