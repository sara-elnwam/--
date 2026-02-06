import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

AttendanceModel attendanceModelFromJson(String str) => AttendanceModel.fromJson(json.decode(str));

class AttendanceModel {
  bool? status;
  String? message;
  List<AttendanceData>? data;

  AttendanceModel({this.status, this.message, this.data});

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      data = <AttendanceData>[];
      json['data'].forEach((v) {
        data!.add(AttendanceData.fromJson(v));
      });
    }
  }
}

class AttendanceData {
  String? date;
  String? checkInTime;
  String? checkOutTime;
  String? workingHours;
  String? locationName;

  AttendanceData({this.date, this.checkInTime, this.checkOutTime, this.workingHours, this.locationName});

  AttendanceData.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    workingHours = json['workingHours'];
    locationName = json['locationName'];
  }
}


class EmployeeAttendanceHistoryScreen extends StatefulWidget {
  const EmployeeAttendanceHistoryScreen({super.key});

  @override
  State<EmployeeAttendanceHistoryScreen> createState() => _EmployeeAttendanceHistoryScreenState();
}

class _EmployeeAttendanceHistoryScreenState extends State<EmployeeAttendanceHistoryScreen> {
  bool _isLoading = true;
  Map<String, List<AttendanceData>> _groupedAttendance = {};
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
      final prefs = await SharedPreferences.getInstance();
      String empId = prefs.getString('user_id') ?? "5";

      final url = 'https://nour-al-eman.runasp.net/api/Locations/GetAll-employee-attendance-ByEmpId?EmpId=$empId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final attendanceModel = attendanceModelFromJson(response.body);
        _processData(attendanceModel.data ?? []);
      }
    } catch (e) {
      debugPrint("خطأ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(List<AttendanceData> rawData) {
    Map<String, List<AttendanceData>> groups = {};
    List<AttendanceData> validData = rawData.where((item) =>
    _parseServerDate(item.date) != null).toList();

    validData.sort((a, b) =>
        _parseServerDate(b.date)!.compareTo(_parseServerDate(a.date)!));

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
        appBar: AppBar(
          title: const Text("  ",
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                  fontSize: 16,
                 )),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.5,

          automaticallyImplyLeading: false,
          leading: null,
        ),
        body: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF1976D2)))
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
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
                Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
            onPressed: _currentMonthIndex > 0
                ? () => setState(() => _currentMonthIndex--) : null,
          ),
          const SizedBox(width: 15),
          Text(
            _availableMonths[_currentMonthIndex],
            style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Almarai'),
          ),
          const SizedBox(width: 15),
          IconButton(
            icon: const Icon(
                Icons.arrow_forward_ios, size: 20, color: Colors.black87),
            onPressed: _currentMonthIndex < _availableMonths.length - 1
                ? () => setState(() => _currentMonthIndex++) : null,
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
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          _headerItem("اليوم"),
          _headerItem("حضور"),
          _headerItem("إنصراف"),
          _headerItem("ساعات"),
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
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 12,
            fontFamily: 'Almarai'
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    String currentMonth = _availableMonths[_currentMonthIndex];
    List<AttendanceData> logs = _groupedAttendance[currentMonth]!;

    return ListView.builder(
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
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      date != null ? DateFormat('MM/dd').format(date) : "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  log.checkInTime ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  log.checkOutTime ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  log.workingHours ?? "--",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E3542)),
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
        "لا توجد بيانات!",
        style: TextStyle(
          color: Colors.red,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Almarai',
        ),
      ),
    );
  }
}