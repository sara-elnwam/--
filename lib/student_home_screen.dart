import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

// الثوابت البصرية
const Color kPrimaryBlue = Color(0xFF07427C);
const Color kSecondaryBlue = Color(0xFFEBF4FF);
const Color kTextDark = Color(0xFF2E3542);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kSuccessGreen = Color(0xFF16A34A);
const Color kDangerRed = Color(0xFFDC2626);
const Color kHeaderBg = Color(0xFFF8FAFC); // ضيفي السطر ده مع الثوابت فوق
const String baseUrl = 'https://nour-al-eman.runasp.net/api';

class StudentHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? loginData;
  const StudentHomeScreen({super.key, this.loginData});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isAttendanceLoading = false;
  Map<String, dynamic>? studentFullData;
  List<dynamic> attendanceList = [];
  late AnimationController _pageAnimationController;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  String _getDayName(int dayNumber) {
    const days = {
      1: "السبت", 2: "الأحد", 3: "الإثنين", 4: "الثلاثاء",
      5: "الأربعاء", 6: "الخميس", 7: "الجمعة",
    };
    return days[dayNumber] ?? "";
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    String? studentIdStr;
    String? token;

    token = widget.loginData?['token']?.toString() ?? prefs.getString('user_token');
    studentIdStr = widget.loginData?['userId']?.toString() ?? prefs.getString('student_id');

    if (studentIdStr == null || studentIdStr.isEmpty || int.tryParse(studentIdStr) == null) {
      _forceLogout();
      return;
    }

    await _fetchStudentProfile(studentIdStr, token);
    _pageAnimationController.forward();
  }

  Future<void> _fetchStudentProfile(String id, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Student/GetById?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          studentFullData = json['data'] ?? json;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isAttendanceLoading = true);
    try {
      final id = studentFullData?['id']?.toString();
      final response = await http.get(Uri.parse('$baseUrl/Student/GetAttendanceByStudentId?id=$id'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() => attendanceList = json['data'] ?? []);
      }
    } finally {
      setState(() => _isAttendanceLoading = false);
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) =>  LoginScreen()), (route) => false);
    }
  }

  // --- UI Components ---

  void _showTeacherComment(dynamic record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("تفاصيل تعليق المعلم", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const Divider(height: 30),
            _commentDetailRow("التعليق:", record['note'] ?? "لا يوجد تعليق"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSecondaryBlue, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: kPrimaryBlue),
                  const SizedBox(width: 10),
                  Text("التقييم : ${record['points'] ?? 0} نقطة",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _commentDetailRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kLabelGrey)),
      const SizedBox(width: 10),
      Expanded(child: Text(value, style: const TextStyle(color: kTextDark))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryBlue)));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: kPrimaryBlue),
          title: Text(_titles[_selectedIndex], style: const TextStyle(color: kPrimaryBlue, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        drawer: _buildWebSidebar(),
        body: FadeTransition(
          opacity: _pageAnimationController,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(_pageAnimationController),
            child: _getPage(_selectedIndex),
          ),
        ),
      ),
    );
  }

  final List<String> _titles = ["البيانات الشخصية", "حضور و غياب", "مقررات المستوي", "أعمال الطالب", "الاختبارات"];

  Widget _getPage(int index) {
    switch (index) {
      case 0: return _buildProfileTab();
      case 1: return _buildAttendanceTab();
      default: return Center(child: Text(_titles[index]));
    }
  }

  // --- صفحة البيانات الشخصية (بدون أي تغيير في المحتوى) ---
  Widget _buildProfileTab() {
    final data = studentFullData;
    final loc = data?['loc'];
    final group = data?['group'];
    final level = group?['level'] ?? data?['level'];
    final teacher = group?['emp'];

    String sessionTimes = "غير محدد";
    if (group?['groupSessions'] != null) {
      List sessions = group['groupSessions'];
      sessionTimes = sessions.map((s) => "${_getDayName(s['day'] ?? 0)} ${s['hour'] ?? ""}").join(" - ");
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("الصفحة الرئيسية", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildFigmaBox(title: "بيانات الطالب :", icon: Icons.badge_outlined, children: [
          _figmaRow("اسم الطالب :", data?['name'] ?? "غير متوفر"),
          _figmaRow("كود الطالب :", data?['id']?.toString() ?? "غير متوفر"),
          _figmaRow("المكتب التابع له :", loc?['name'] ?? "غير متوفر"),
          _figmaRow("موعد الالتحاق بالمدرسة :", data?['joinDate']?.toString().split('T')[0] ?? "غير متوفر"),
          _figmaRow("اسم المدرسة الحكومية :", data?['governmentSchool'] ?? "غير متوفر"),
        ]),
        const SizedBox(height: 12),
        _buildFigmaBox(title: "المدرسة :", icon: Icons.account_balance_outlined, children: [
          _figmaRow("مجموعة :", group?['name'] ?? "غير متوفر"),
          _figmaRow("المستوي :", level?['name'] ?? "غير متوفر"),
          _figmaRow("اسم المعلم :", teacher?['name'] ?? "غير متوفر"),
          _figmaRow("الحضور :", data?['attendanceType'] ?? "غير متوفر"),
          _figmaRow("موعد الحلقة :", sessionTimes),
        ]),
        const SizedBox(height: 12),
        _buildFigmaBox(title: "الاشتراك :", icon: Icons.card_membership_outlined, children: [
          _figmaRow("موعد الاشتراك القادم :", data?['nextPaymentDate']?.toString().split('T')[0] ?? "غير متوفر"),
          _figmaRow("عدد النقاط :", data?['points']?.toString() ?? "0"),
          _figmaRow("مدة الاشتراك :", data?['paymentType'] ?? "غير متوفر"),
        ]),
      ],
    );
  }

  // --- صفحة الحضور والغياب (التصميم الجديد) ---
  Widget _buildAttendanceTab() {
    if (_isAttendanceLoading) return const Center(child: CircularProgressIndicator());
    if (attendanceList.isEmpty) return Center(child: ElevatedButton(onPressed: _fetchAttendance, child: const Text("تحميل جدول الحضور")));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("سجل حضور و غياب الطالب للمستوى الحالي", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(kHeaderBg),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('موعد الحلقة', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('الحضور', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('حفظ قديم', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('حفظ جديد', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('تعليق المعلم', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: attendanceList.map((record) {
                  bool isPresent = record['status'] == "حضور" || record['status'] == true;
                  return DataRow(cells: [
                    DataCell(Text(record['date']?.split('T')[0] ?? "")),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPresent ? kSuccessGreen.withOpacity(0.1) : kDangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(isPresent ? "حضور" : "غياب",
                          style: TextStyle(color: isPresent ? kSuccessGreen : kDangerRed, fontWeight: FontWeight.bold, fontSize: 12)),
                    )),
                    DataCell(Text(record['oldReview'] ?? "---")),
                    DataCell(Text(record['newReview'] ?? "---")),
                    DataCell(TextButton(
                      onPressed: () => _showTeacherComment(record),
                      child: const Text("عرض التعليق", style: TextStyle(color: kPrimaryBlue, decoration: TextDecoration.underline)),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildFigmaBox({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor.withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: kPrimaryBlue, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const Divider(height: 15),
        ...children,
      ]),
    );
  }

  Widget _figmaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }

  Widget _buildWebSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(children: [
          const SizedBox(height: 60),
          const CircleAvatar(radius: 45, backgroundColor: kSecondaryBlue, child: Icon(Icons.person, size: 50, color: kPrimaryBlue)),
          const SizedBox(height: 15),
          Text(studentFullData?['name'] ?? "اسم الطالب", style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const Divider(height: 40),
          _drawerItem(0, Icons.person_outline, "البيانات الشخصية"),
          _drawerItem(1, Icons.calendar_today_outlined, "حضور و غياب"),
          _drawerItem(2, Icons.book_outlined, "مقررات المستوي"),
          _drawerItem(3, Icons.assignment_outlined, "أعمال الطالب"),
          _drawerItem(4, Icons.quiz_outlined, "الاختبارات"),
          const Spacer(),
          _drawerItem(5, Icons.logout, "تسجيل الخروج", isLogout: true),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title, {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: kSecondaryBlue,
      leading: Icon(icon, color: isLogout ? kDangerRed : (isSelected ? kPrimaryBlue : kLabelGrey)),
      title: Text(title, style: TextStyle(color: isLogout ? kDangerRed : (isSelected ? kPrimaryBlue : kTextDark), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (isLogout) {
          _forceLogout();
        } else {
          Navigator.pop(context);
          setState(() => _selectedIndex = index);
          _pageAnimationController.reset();
          _pageAnimationController.forward();
          if (index == 1) _fetchAttendance();
        }
      },
    );
  }
}