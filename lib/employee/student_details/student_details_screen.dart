import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryBlue = Color(0xFF07427C);
const Color kAccentOrange = Color(0xFFF59E0B);
const Color kTextDark = Color(0xFF2E3542);

class StudentDetailsScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const StudentDetailsScreen({required this.studentId, required this.studentName});

  @override
  _StudentDetailsScreenState createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? studentData;
  List<dynamic> attendanceList = [];
  bool isLoadingInfo = true;
  bool isLoadingAttendance = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStudentInfo();

    _tabController.addListener(() {
      if (_tabController.index == 2 && attendanceList.isEmpty && !isLoadingAttendance) {
        _fetchAttendance();
      }
    });
  }

  Future<void> _fetchStudentInfo() async {
    setState(() => isLoadingInfo = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Student/GetById?id=${widget.studentId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        setState(() {
          studentData = jsonDecode(response.body)['data'];
          isLoadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingInfo = false);
    }
  }
  Future<void> _fetchAttendance() async {
    setState(() => isLoadingAttendance = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // الاحتمال القوي جداً: الـ ID بيمرر كـ Path Parameter
      // جرب هذا الرابط أولاً:
      final url = 'https://nour-al-eman.runasp.net/api/Attendance/GetByStudentId/${widget.studentId}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("Final Attempt URL: $url");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          attendanceList = decoded is List ? decoded : (decoded['data'] ?? []);
          isLoadingAttendance = false;
        });
      } else {
        // لو جاب 404 تاني، جرب تغير الرابط في الكود فوق لـ:
        // 'https://nour-al-eman.runasp.net/api/Student/Attendance/${widget.studentId}'
        setState(() => isLoadingAttendance = false);
      }
    } catch (e) {
      debugPrint("Catch Error: $e");
      if (mounted) setState(() => isLoadingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("بيانات الطالب",
              style: TextStyle(color: kTextDark, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: kPrimaryBlue),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: kPrimaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryBlue,
            tabs: const [Tab(text: "البيانات"), Tab(text: "الاختبارات"), Tab(text: "الحضور")],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            isLoadingInfo ? const Center(child: CircularProgressIndicator()) : _buildInfoTab(),
            const Center(child: Text("تبويب الاختبارات")),
            _buildAttendanceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (studentData == null) return const Center(child: Text("لا توجد بيانات"));
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildCompactCard("بيانات الطالب", [
          _infoRow("اسم الطالب :", studentData!['name'] ?? "---"),
          _infoRow("كود الطالب :", studentData!['id']?.toString() ?? "---"),
          _infoRow("اسم المدرسة الحكومية :", studentData!['governmentSchool'] ?? "---"),
          _infoRow("موعد الالتحاق بالمدرسة :", studentData!['joinDate']?.toString().substring(0, 10) ?? "---"),
          _infoRow("العنوان :", studentData!['address'] ?? "---"),
          _infoRow("وظيفة ولي الأمر :", studentData!['parentJob'] ?? "---"),
          _infoRow("حالة الطالب :", studentData!['status'] == true ? "نشط" : "غير نشط"),
          _infoRow("رقم هاتف ولي الأمر :", studentData!['phone'] ?? "---"),
          _infoRow("الكراسة :", "---"),
          _infoRow("حالة الدفع :", studentData!['paymentType'] ?? "---"),
          _infoRow("العمر :", "---"),
        ]),
        const SizedBox(height: 15),
        _buildCompactCard("المدرسة", [
          _infoRow("مجموعة :", studentData!['group']?['name'] ?? "---"),
          _infoRow("المستوى :", studentData!['level']?['name'] ?? "---"),
          _infoRow("اسم المعلم :", studentData!['group']?['emp']?['name'] ?? "---"),
          _infoRow("الحضور :", studentData!['attendanceType'] ?? "---"),
          _infoRow("موعد الحلقة :", "السبت - الأحد - الإثنين"),
        ]),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (isLoadingAttendance) return const Center(child: CircularProgressIndicator());
    if (attendanceList.isEmpty) return const Center(child: Text("لا توجد سجلات حضور (تأكد من رابط الـ API)"));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text("موعد الحلقة", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("الحضور", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("حفظ قديم", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("حفظ جديد", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("تعليق المعلم", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: attendanceList.map((item) {
                String status = (item['status'] == "حضور" || item['status'] == true) ? "حضور" : "غياب";
                return DataRow(cells: [
                  DataCell(Text(item['date']?.toString().substring(0, 10) ?? "---")),
                  DataCell(Text(status, style: TextStyle(color: status == "حضور" ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                  DataCell(Text(item['oldSafe']?.toString() ?? "---")),
                  DataCell(Text(item['newSafe']?.toString() ?? "---")),
                  DataCell(const Text("------", style: TextStyle(color: Colors.grey))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(title, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(12), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Expanded(child: Text(value, textAlign: TextAlign.left, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }
}