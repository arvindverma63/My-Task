import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/employee_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateEmployeeReport(List<Employee> employees, Map<String, List<AttendanceEntry>> allAttendance) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Employee Management Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Contact', 'Joining Date', 'Base Salary', 'Status'],
              data: employees.map((emp) {
                final suffix = emp.salaryBasis == 'monthly' ? ' / mo' : ' / day';
                return [
                  emp.name,
                  emp.contact,
                  DateFormat('dd/MM/yyyy').format(emp.joiningDate),
                  'Rs. ${emp.baseSalary}$suffix',
                  emp.relievingDate == null ? 'Active' : 'Relieved',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateAttendanceReport(DateTime date, List<Employee> employees, Map<String, List<AttendanceEntry>> dailyStatus) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Daily Attendance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateFormat('dd MMMM yyyy').format(date)}', style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Employee Name', 'Status', 'In Time', 'Out Time', 'Payment'],
              data: employees.expand((emp) {
                final list = dailyStatus[emp.id] ?? [];
                if (list.isEmpty) {
                  return [
                    [emp.name, 'N/A', '--:--', '--:--', '--']
                  ];
                }
                return list.map((status) => [
                  emp.name,
                  status.status.name.toUpperCase(),
                  status.checkInTime ?? '--:--',
                  status.checkOutTime ?? '--:--',
                  status.amountGiven > 0 ? 'Rs. ${status.amountGiven}' : '--',
                ]);
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
