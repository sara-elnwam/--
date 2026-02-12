import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// --- Models ---
class EmployeeAttendanceModel {
  bool? status;
  String? message;
  List<AttendanceRecord>? data;

  EmployeeAttendanceModel({this.status, this.message, this.data});

  EmployeeAttendanceModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <AttendanceRecord>[];
      json['data'].forEach((v) {
        data!.add(AttendanceRecord.fromJson(v));
      });
    }
  }
}

class AttendanceRecord {
  String? date;
  String? checkInTime;
  String? checkOutTime;
  String? workingHours;
  String? locationName;

  AttendanceRecord({this.date, this.checkInTime, this.checkOutTime, this.workingHours, this.locationName});

  AttendanceRecord.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    workingHours = json['workingHours'];
    locationName = json['locationName'];
  }
}

// --- Screen ---
class SpecificEmployeeAttendanceScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const SpecificEmployeeAttendanceScreen({
    super.key,
    required this.employeeId,
    required this.employeeName
  });

  @override
  State<SpecificEmployeeAttendanceScreen> createState() => _SpecificEmployeeAttendanceScreenState();
}

class _SpecificEmployeeAttendanceScreenState extends State<SpecificEmployeeAttendanceScreen> {
  bool _isLoading = true;
  Map<String, List<AttendanceRecord>> _groupedAttendance = {};
  List<String> _availableMonths = [];
  int _currentMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLogs();
  }

  DateTime? _parseServerDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        return DateFormat("MM/dd/yyyy").parse(dateStr);
      } catch (e2) {
        return null;
      }
    }
  }

  Future<void> _fetchAttendanceLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final url = 'https://nour-al-eman.runasp.net/api/Locations/GetAll-employee-attendance-ByEmpId?EmpId=${widget.employeeId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final attendanceModel = EmployeeAttendanceModel.fromJson(json.decode(response.body));
        _processData(attendanceModel.data ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(List<AttendanceRecord> rawData) {
    Map<String, List<AttendanceRecord>> groups = {};
    List<AttendanceRecord> validData = rawData.where((item) => _parseServerDate(item.date) != null).toList();

    validData.sort((a, b) => _parseServerDate(b.date)!.compareTo(_parseServerDate(a.date)!));

    for (var entry in validData) {
      DateTime date = _parseServerDate(entry.date)!;
      String monthYear = DateFormat('MMMM yyyy', 'ar').format(date);
      if (!groups.containsKey(monthYear)) groups[monthYear] = [];
      groups[monthYear]!.add(entry);
    }

    setState(() {
      _groupedAttendance = groups;
      _availableMonths = groups.keys.toList();
      _currentMonthIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        // تم حذف الـ AppBar بناءً على طلبك
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
            : _availableMonths.isEmpty
            ? _buildEmptyState()
            : Column(
          children: [
            _buildMonthNavigator(),
            _buildTableHeader(),
            Expanded(child: _buildAttendanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Container(
      width: double.infinity, // كبرنا العرض
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // زيادة الحواف الداخلية
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع العناصر على الأطراف
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
            onPressed: _currentMonthIndex > 0
                ? () => setState(() => _currentMonthIndex--) : null,
          ),
          Text(
            _availableMonths[_currentMonthIndex],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black87),
            onPressed: _currentMonthIndex < _availableMonths.length - 1 ? () => setState(() => _currentMonthIndex++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _headerItem("اليوم"),
          _headerItem("حضور"),
          _headerItem("إنصراف"),
          _headerItem("ساعات العمل"),
        ],
      ),
    );
  }

  Widget _headerItem(String label) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13, fontFamily: 'Almarai'),
      ),
    );
  }

  Widget _buildAttendanceList() {
    String currentMonth = _availableMonths[_currentMonthIndex];
    List<AttendanceRecord> logs = _groupedAttendance[currentMonth]!;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        DateTime? date = _parseServerDate(log.date);

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      date != null ? DateFormat('EEEE', 'ar').format(date) : "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
                    ),
                    Text(
                      date != null ? DateFormat('MM/dd').format(date) : "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  log.checkInTime ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  log.checkOutTime ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  log.workingHours ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E3542)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "لا توجد بيانات حضور",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Almarai',
        ),
      ),
    );
  }
}