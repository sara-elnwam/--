import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AttendanceLogsTab extends StatefulWidget {
  final int empId;

  const AttendanceLogsTab({super.key, required this.empId});

  @override
  State<AttendanceLogsTab> createState() => _AttendanceLogsTabState();
}

class _AttendanceLogsTabState extends State<AttendanceLogsTab> {
  List<dynamic> attendanceLogs = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLogs();
  }

// داخل ملف attendance_logs_tab.dart

  Future<void> _fetchAttendanceLogs() async {
    try {
      final url = 'https://nour-al-eman.runasp.net/api/Locations/GetAllEmployeeAttendanceById?EmpId=${widget.empId}';
      final response = await http.get(Uri.parse(url));

      // التحقق من أن الوجت لا تزال موجودة قبل تحديث الحالة
      if (!mounted) return;

      // داخل دالة _fetchAttendanceLogs في ملف attendance_logs_tab.dart
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          attendanceLogs = data['data'] ?? [];
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // بدلاً من عرض "خطأ 404"، اعرضي رسالة مستخدم لطيفة
        setState(() {
          attendanceLogs = []; // قائمة فارغة
          errorMessage = "لا يوجد سجل حضور وانصراف مسجل لهذا المعلم حالياً";
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "فشل تحميل البيانات: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      // التحقق مرة أخرى في حالة الخطأ
      if (!mounted) return;
      setState(() {
        errorMessage = "خطأ في الاتصال بالشبكة";
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)));
    if (errorMessage.isNotEmpty) return Center(child: Text(errorMessage));
    if (attendanceLogs.isEmpty) return const Center(child: Text("لا توجد سجلات حضور حالياً"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceLogs.length,
      itemBuilder: (context, index) {
        final log = attendanceLogs[index];
        return _buildAttendanceCard(log);
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                log['date'] ?? "---",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3542)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: // داخل _buildAttendanceCard في ملف attendance_logs_tab.dart
                Text(
                  log['locationName'] ?? log['locName'] ?? "موقع غير محدد",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeStat("حضور", log['checkInTime'] ?? "--:--", Colors.green),
              _buildTimeStat("انصراف", log['checkOutTime'] ?? "--:--", Colors.orange),
              _buildTimeStat("ساعات العمل", log['workingHours'] ?? "00:00", const Color(0xFF07427C)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStat(String label, String time, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}