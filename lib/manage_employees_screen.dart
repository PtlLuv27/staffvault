import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_employee_screen.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() async {
    final data = await DatabaseHelper.instance.queryAllEmployees();
    setState(() {
      _employees = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Employees")),
      body: _employees.isEmpty
          ? const Center(child: Text("No employees added yet."))
          : ListView.builder(
        itemCount: _employees.length,
        itemBuilder: (context, index) {
          final emp = _employees[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(emp['name']),
              subtitle: Text("${emp['salaryType']} - Rs. ${emp['salaryAmount']}"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  // Navigate to AddEmployeeScreen in "Edit Mode"
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEmployeeScreen(employee: emp),
                    ),
                  ).then((_) => _refreshList());
                },
              ),
            ),
          );
        },
      ),
      // Requirement 1: Add employee button moved here
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEmployeeScreen()),
        ).then((_) => _refreshList()),
        child: const Icon(Icons.add),
      ),
    );
  }
}