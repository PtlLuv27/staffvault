import 'package:flutter/material.dart';
import 'database_helper.dart';

class AddEmployeeScreen extends StatefulWidget {
  // Added optional employee parameter to fix the "named parameter isn't defined" error
  final Map<String, dynamic>? employee;
  const AddEmployeeScreen({super.key, this.employee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Use Controllers to pre-fill data if editing
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryAmountController;

  String _salaryType = 'Monthly';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if widget.employee is not null
    _nameController = TextEditingController(text: widget.employee?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.employee?['phone'] ?? '');
    _salaryAmountController = TextEditingController(
        text: widget.employee?['salaryAmount']?.toString() ?? '');
    _salaryType = widget.employee?['salaryType'] ?? 'Monthly';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryAmountController.dispose();
    super.dispose();
  }

  void _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final employeeData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'salaryType': _salaryType,
        'salaryAmount': double.parse(_salaryAmountController.text),
      };

      if (widget.employee == null) {
        // Mode: Create New
        await DatabaseHelper.instance.insertEmployee({
          ...employeeData,
          'joiningDate': DateTime.now().toIso8601String(),
        });
      } else {
        // Mode: Edit Existing
        await DatabaseHelper.instance.updateEmployee(
          widget.employee!['id'],
          employeeData,
        );
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.employee != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Employee" : "Add New Employee")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Employee Name'),
                validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              DropdownButtonFormField<String>(
                value: _salaryType,
                items: ['Monthly', 'Daily'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _salaryType = value!),
                decoration: const InputDecoration(labelText: 'Salary Type'),
              ),
              TextFormField(
                controller: _salaryAmountController,
                decoration: const InputDecoration(labelText: 'Salary Amount'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _saveEmployee,
                child: Text(isEditing ? "Update Profile" : "Save Employee"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}