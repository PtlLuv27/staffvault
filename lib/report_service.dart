import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class ReportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> generateMonthlyReport(int empId, String yearMonth) async {
    final employees = await _dbHelper.queryAllEmployees();
    final employee = employees.firstWhere((e) => e['id'] == empId);
    final logs = await _dbHelper.getAttendanceForMonth(empId, yearMonth);

    // 1. Prepare Table Data for 1st to Last Day
    List<List<dynamic>> tableData = [
      ['Date', 'Status', 'Addons', 'Note', 'Daily Net']
    ];

    int year = int.parse(yearMonth.split('-')[0]);
    int month = int.parse(yearMonth.split('-')[1]);
    int daysInMonth = DateTime(year, month + 1, 0).day; // Get total days

    double totalEarnings = 0;
    double totalBonus = 0;
    double totalLoan = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      String date = "$yearMonth-${i.toString().padLeft(2, '0')}";
      var log = logs.firstWhere((l) => l['date'] == date, orElse: () => {});

      double b = (log['bonus'] ?? 0.0).toDouble();
      double l = (log['loan'] ?? 0.0).toDouble();

      // Daily Salary Calculation
      double dailyRate = (employee['salaryType'] == 'Monthly'
          ? (employee['salaryAmount'] ?? 0) / 30
          : (employee['salaryAmount'] ?? 0));

      double statusMult = log['status'] == 'Present' ? 1.0
          : (log['status'] == 'Half-day' ? 0.5 : 0.0);

      double dailyEarned = dailyRate * statusMult;
      double dailyNet = dailyEarned + b - l;

      // Accumulate totals for summary
      totalEarnings += dailyEarned;
      totalBonus += b;
      totalLoan += l;

      tableData.add([
        i.toString(),
        log['status'] ?? 'Not Marked',
        // Feature 3: Stacked addons with color indicators
        pw.Column(
          children: [
            if (b > 0) pw.Text("+Rs. $b", style: const pw.TextStyle(color: PdfColors.green)),
            if (l > 0) pw.Text("-Rs. $l", style: const pw.TextStyle(color: PdfColors.red)),
          ],
        ),
        log['note'] ?? '',
        pw.Text("Rs. ${dailyNet.toStringAsFixed(2)}",
            style: pw.TextStyle(color: dailyNet < 0 ? PdfColors.red : PdfColors.black)),
      ]);
    }

    double finalNetSalary = totalEarnings + totalBonus - totalLoan;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage( // Use MultiPage to handle long tables
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Header(
              level: 0,
              child: pw.Text("StaffVault: Monthly Attendance Ledger",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))
          ),
          pw.Text("Employee: ${employee['name']} | Period: $yearMonth"),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 10),

          // Feature 3: Detailed Table with Padding
          pw.TableHelper.fromTextArray(
            context: context,
            cellPadding: const pw.EdgeInsets.all(5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            data: tableData,
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),

          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Total Attendance Earnings: Rs. ${totalEarnings.toStringAsFixed(2)}"),
                pw.Text("Total Bonus: +Rs. ${totalBonus.toStringAsFixed(2)}", style: const pw.TextStyle(color: PdfColors.green)),
                pw.Text("Total Loans: -Rs. ${totalLoan.toStringAsFixed(2)}", style: const pw.TextStyle(color: PdfColors.red)),
                pw.SizedBox(
                    width: 150,
                    child: pw.Divider(thickness: 1)
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: finalNetSalary < 0 ? PdfColors.red : PdfColors.green800),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    "Net Payable: Rs. ${finalNetSalary.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: finalNetSalary < 0 ? PdfColors.red : PdfColors.green800
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Detailed_Report_${employee['name']}_$yearMonth.pdf',
    );
  }
}