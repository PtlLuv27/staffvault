import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'report_service.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  int? _selectedEmpId;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _employees = [];
  Map<String, dynamic>? _previewData;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    final data = await DatabaseHelper.instance.queryAllEmployees();
    setState(() { _employees = data; });
  }

  String get _formattedMonth => "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";

  void _calculatePreview() async {
    if (_selectedEmpId == null) return;

    final logs = await DatabaseHelper.instance.getAttendanceForMonth(_selectedEmpId!, _formattedMonth);
    final employee = _employees.firstWhere((e) => e['id'] == _selectedEmpId);

    int present = logs.where((l) => l['status'] == 'Present').length;
    int halfDay = logs.where((l) => l['status'] == 'Half-day').length;

    // Using ?? 0.0 to prevent null errors during calculation
    double bonus = logs.fold(0.0, (sum, item) => sum + (item['bonus'] ?? 0.0));
    double loan = logs.fold(0.0, (sum, item) => sum + (item['loan'] ?? 0.0));

    double base = employee['salaryAmount'] ?? 0.0;
    double earned = (employee['salaryType'] == 'Monthly' ? base / 30 : base) * (present + (halfDay * 0.5));

    setState(() {
      _previewData = {
        'earned': earned,
        'bonus': bonus,
        'loan': loan,
        'net': earned + bonus - loan,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Salary Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0), // FIXED: Padding is inside Card
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "Select Employee"),
                      value: _selectedEmpId,
                      items: _employees.map((e) => DropdownMenuItem<int>(
                          value: e['id'],
                          child: Text(e['name'])
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedEmpId = val);
                        _calculatePreview();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Month: $_formattedMonth", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                              _calculatePreview();
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text("Select Month"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_previewData != null) ...[
              _buildPreviewCard(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () => ReportService().generateMonthlyReport(_selectedEmpId!, _formattedMonth),
                  icon: const Icon(Icons.download),
                  label: const Text("DOWNLOAD PDF"),
                ),
              ),
            ] else
              const Expanded(child: Center(child: Text("Select employee to see preview"))),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _row("Earnings", "₹${_previewData!['earned'].toStringAsFixed(2)}"),
            _row("Bonus", "+₹${_previewData!['bonus'].toStringAsFixed(2)}", color: Colors.green),
            _row("Loan", "-₹${_previewData!['loan'].toStringAsFixed(2)}", color: Colors.red),
            const Divider(),
            _row("Net Total", "₹${_previewData!['net'].toStringAsFixed(2)}", bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String val, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}