import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; //
import 'database_helper.dart';
import 'attendance_screen.dart';
import 'auth_service.dart';
import 'employee_detail_screen.dart';
import 'reports_list_screen.dart';
import 'salary_dashboard_screen.dart';
import 'manage_employees_screen.dart';
import 'main.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();

  // Interactive Stats Variables
  int _total = 0, _present = 0, _absent = 0, _halfDay = 0;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  // Refresh both employee list and today's statistics
  void _refreshDashboard() async {
    final data = await DatabaseHelper.instance.queryAllEmployees();
    final today = DateTime.now().toString().split(' ')[0];
    final logs = await DatabaseHelper.instance.getAttendanceForDate(today);

    int p = 0, h = 0;
    for (var log in logs) {
      if (log['status'] == 'Present') p++;
      else if (log['status'] == 'Half-day') h++;
    }

    setState(() {
      _allEmployees = data;
      _filteredEmployees = data;
      _total = data.length;
      _present = p;
      _halfDay = h;
      _absent = _total - (p + h); // Calculate absent as the remainder
    });
  }

  void _filterEmployees(String query) {
    setState(() {
      _filteredEmployees = _allEmployees
          .where((emp) => emp['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StaffVault Dashboard")),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildInteractiveStatsCard(), // Step 1: Interactive Dashboard
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Employee...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _filterEmployees,
            ),
          ),
          Expanded(
            child: _filteredEmployees.isEmpty
                ? const Center(child: Text("No employees found."))
                : ListView.builder(
              itemCount: _filteredEmployees.length,
              itemBuilder: (context, index) {
                final emp = _filteredEmployees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(emp['name']),
                    subtitle: Text("${emp['salaryType']} - Rs. ${emp['salaryAmount']}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employee: emp)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Feature 1: Summary Card with Pie Chart
  Widget _buildInteractiveStatsCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  const SizedBox(height: 12),
                  _statItem("Total Staff", _total.toString(), Colors.black),
                  _statItem("Present", _present.toString(), Colors.green),
                  _statItem("Half-day", _halfDay.toString(), Colors.orange),
                  _statItem("Absent", _absent.toString(), Colors.red),
                ],
              ),
            ),
            // Pie Chart Widget
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 25,
                    sections: [
                      PieChartSectionData(value: _present.toDouble(), color: Colors.green, radius: 12, showTitle: false),
                      PieChartSectionData(value: _halfDay.toDouble(), color: Colors.orange, radius: 12, showTitle: false),
                      PieChartSectionData(value: _absent.toDouble(), color: Colors.red, radius: 12, showTitle: false),
                      if (_total == 0) PieChartSectionData(value: 1, color: Colors.grey.shade300, radius: 12, showTitle: false),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text("StaffVault Menu", style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Homepage"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt),
            title: const Text("Manage Employees"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageEmployeesScreen()))
                  .then((_) => _refreshDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text("Attendance"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AttendanceScreen()))
                  .then((_) => _refreshDashboard()); // Refresh stats on return
            },
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text("Salary Dashboard"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SalaryDashboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text("Generate Report"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsListScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen(message: "Visit Again!", isLoggingOut: true)),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}