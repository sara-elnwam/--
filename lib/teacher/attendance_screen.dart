import 'dart:ui' as ui; // هذا السطر هو المفتاح لاستخدام ui.TextDirection
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<AttendanceData> _attendanceList = [];

  @override
  void initState() {
    super.initState();
    // تهيئة بيانات اللغة العربية قبل جلب البيانات
    initializeDateFormatting('ar', null).then((_) {
      _fetchAttendance();
    });
  }

  Future<void> _fetchAttendance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String empId = prefs.getString('user_id') ?? "6";
      final url = 'https://nour-al-eman.runasp.net/api/Locations/GetAllEmployeeAttendanceById?EmpId=$empId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final model = attendanceModelFromJson(response.body);
        if (mounted) {
          setState(() {
            _attendanceList = model.data ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching attendance: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + increment);
    });
    _fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // تم تغييرها لضمان التعرف على القيمة
      textDirection: ui.TextDirection.rtl, // استخدام اللاحقة ui لضمان الوصول للتعريف الصحيح
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            "حضور و انصراف المعلم",
            style: TextStyle(
                color: Color(0xFF2E3542),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Almarai'
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black54),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'ar').format(_selectedDate),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3542),
                        fontFamily: 'Almarai'
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black54),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
                  : _attendanceList.isEmpty
                  ? const Center(child: Text("لا توجد سجلات لهذا الشهر", style: TextStyle(fontFamily: 'Almarai')))
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: DataTable(
                    columnSpacing: 30,
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                    columns: [
                      DataColumn(label: Text('اليوم', style: _headerStyle)),
                      DataColumn(label: Text('حضور', style: _headerStyle)),
                      DataColumn(label: Text('انصراف', style: _headerStyle)),
                      DataColumn(label: Text('ساعات العمل', style: _headerStyle)),
                    ],
                    // استبدل جزء الـ rows في DataTable بهذا الكود المطور:
                    rows: _attendanceList.where((item) {
                      if (item.date == null) return false;
                      try {
                        // السيرفر يرسل التاريخ هكذا: 11/13/2023
                        List<String> dateParts = item.date!.split('/');
                        int month = int.parse(dateParts[0]);
                        int year = int.parse(dateParts[2]);

                        // نقارن فقط إذا كان الشهر والسنة يطابقان ما اختاره المستخدم في الواجهة
                        return month == _selectedDate.month && year == _selectedDate.year;
                      } catch (e) {
                        return false;
                      }
                    }).map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.date ?? "", style: _cellStyle)),
                        DataCell(Text(item.checkInTime ?? "--",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(Text(item.checkOutTime ?? "--",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(Text(item.workingHours ?? "00:00:00", style: _cellStyle)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Almarai');
  TextStyle get _cellStyle => const TextStyle(color: Color(0xFF2E3542), fontSize: 12, fontFamily: 'Almarai');
}