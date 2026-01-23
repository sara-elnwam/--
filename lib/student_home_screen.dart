import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // تأكدي أن الملف موجود بنفس الاسم
import 'student_exams_widget.dart';
// الثوابت البصرية
const Color kPrimaryBlue = Color(0xFF07427C);
const Color kSecondaryBlue = Color(0xFFEBF4FF);
const Color kTextDark = Color(0xFF2E3542);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kSuccessGreen = Color(0xFF16A34A);
const Color kDangerRed = Color(0xFFDC2626);
const Color kHeaderBg = Color(0xFFF8FAFC);
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
  List<dynamic> examsList = []; // لتخزين بيانات الاختبارات
  bool _isExamsLoading = false;

  // متغير لتتبع السطر المفتوح حالياً في الجدول
  int? expandedRowIndex;

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

  // ميثود لتحويل أرقام التقييم إلى نص (ممتاز، جيد جداً...)
  String _getEvaluationText(dynamic value) {
    if (value == null || value
        .toString()
        .trim()
        .isEmpty || value.toString() == "null") return "---";

    String valStr = value.toString().trim();

    // إذا كانت القيمة نصية (زي ممتاز، جيد) نرجعها فوراً
    int? score = int.tryParse(valStr);
    if (score == null) return valStr;

    // إذا كانت رقم، نحولها للتقدير المناسب
    if (score >= 90) return "ممتاز";
    if (score >= 80) return "جيد جداً";
    if (score >= 65) return "جيد";
    if (score >= 50) return "مقبول";
    return "ضعيف";
  }

  String _getDayName(int dayNumber) {
    const days = {
      1: "السبت",
      2: "الأحد",
      3: "الإثنين",
      4: "الثلاثاء",
      5: "الأربعاء",
      6: "الخميس",
      7: "الجمعة"
    };
    return days[dayNumber] ?? "";
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = widget.loginData?['userId']?.toString() ??
        widget.loginData?['data']?['id']?.toString() ??
        prefs.getString('student_id');
    String? token = widget.loginData?['token']?.toString() ??
        prefs.getString('user_token');

    if (id == null || id.isEmpty) {
      _forceLogout();
      return;
    }

    await _fetchStudentProfile(id, token);
    _pageAnimationController.forward();
  }

  Future<void> _fetchExams(String id) async {
    setState(() => _isExamsLoading = true);
    try {
      // بناءً على الصورة المرسلة الـ endpoint هي GetExam
      final response = await http.get(
          Uri.parse('$baseUrl/Student/GetExam?id=$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          // نضع الـ data في قائمة لأن الـ Widget تتوقع List
          if (responseData['data'] != null) {
            examsList = [responseData['data']];
          } else {
            examsList = [];
          }
        });
      }
    } catch (e) {
      debugPrint("Exams Error: $e");
    } finally {
      if (mounted) setState(() => _isExamsLoading = false);
    }
  }


  Future<void> _fetchStudentProfile(String id, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Student/GetById?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
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

  Future<void> _fetchAttendance(String id) async {
    setState(() => _isAttendanceLoading = true);
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/Student/GetAttendaceByStudentId?id=$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          attendanceList = responseData['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isAttendanceLoading = false);
    }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => LoginScreen()), (
          route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimaryBlue)));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: kPrimaryBlue),
          title: Text(_titles[_selectedIndex], style: const TextStyle(
              color: kPrimaryBlue, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        drawer: _buildWebSidebar(),
        body: FadeTransition(
          opacity: _pageAnimationController,
          child: _getPage(_selectedIndex),
        ),
      ),
    );
  }

  final List<String> _titles = [
    "البيانات الشخصية",
    "حضور و غياب",
    "مقررات المستوي",
    "أعمال الطالب",
    "الاختبارات"
  ];

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildProfileTab();
      case 1:
        return _buildAttendanceTab();
      case 4:
        return StudentExamsWidget(
            examsList: examsList, isLoading: _isExamsLoading);
      default:
        return Center(child: Text(_titles[index]));
    }
  }

  Widget _buildProfileTab() {
    final data = studentFullData;
    final loc = data?['loc'];
    final group = data?['group'];
    final level = data?['level'];

    String sessionTimes = "غير محدد";
    if (group?['groupSessions'] != null) {
      List sessions = group['groupSessions'];
      sessionTimes =
          sessions.map((s) => "${_getDayName(s['day'] ?? 0)} ${s['hour'] ??
              ""}").join(" - ");
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("البيانات الشخصية", style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 15),

        _buildInfoBox("بيانات الطالب", Icons.person_outline, [
          _infoRow("اسم الطالب :", data?['name'] ?? "---"),
          _infoRow("كود الطالب :", data?['id']?.toString() ?? "---"),
          _infoRow("المكتب التابع له :", loc?['name'] ?? "---"),
          _infoRow("موعد الالتحاق بالمدرسة :",
              data?['joinDate']?.toString().split('T')[0] ?? "---"),
          _infoRow(
              "اسم المدرسة الحكومية :", data?['governmentSchool'] ?? "---"),
        ]),

        _buildInfoBox("المدرسة", Icons.school_outlined, [
          _infoRow("مجموعة :", group?['name'] ?? "---"),
          _infoRow("المستوى :", level?['name'] ?? "---"),
          _infoRow("اسم المعلم :", group?['emp']?['name'] ?? "---"),
          _infoRow("الحضور :", data?['attendanceType'] ?? "---"),
          _infoRow("موعد الحلقة :", sessionTimes),
        ]),

        _buildInfoBox("الاشتراك", Icons.payments_outlined, [
          _infoRow("نوع الاشتراك :", data?['paymentType'] ?? "---"),
          _infoRow("حالة الحساب :", data?['documentType'] ?? "---"),
          _infoRow("عدد النقاط :", loc?['coordinates'] ?? "0"),
        ]),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (_isAttendanceLoading) return const Center(
        child: CircularProgressIndicator(color: kPrimaryBlue));
    if (attendanceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("لا يوجد بيانات سجل حضور حالياً"),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () =>
                _fetchAttendance(studentFullData?['id']?.toString() ?? ""),
                child: const Text("تحديث البيانات")),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("حضور و غياب الطالب للمستوى الحالي", style: TextStyle(
              fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  decoration: const BoxDecoration(color: kHeaderBg,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12))),
                  child: const Row(
                    children: [
                      Expanded(flex: 2,
                          child: Text('موعد الحلقة', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1,
                          child: Text('الحضور', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1,
                          child: Text('حفظ قديم', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1,
                          child: Text('حفظ جديد', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                      Expanded(flex: 1,
                          child: Text('التعليق', style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: attendanceList.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: kBorderColor),
                  itemBuilder: (context, index) {
                    final record = attendanceList[index];
                    bool isPresent = record['isPresent'] == true;
                    bool isExpanded = expandedRowIndex == index;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() =>
                              expandedRowIndex = isExpanded ? null : index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2,
                                    child: Text(
                                        record['createDate']?.toString().split(
                                            'T')[0] ?? "---",
                                        style: const TextStyle(fontSize: 10))),
                                Expanded(flex: 1,
                                    child: Text(isPresent ? "حضور" : "غياب",
                                        style: TextStyle(color: isPresent
                                            ? kSuccessGreen
                                            : kDangerRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10))),
                                Expanded(flex: 1,
                                    child: Text(_getEvaluationText(
                                        record['oldAttendanceNote']),
                                        style: const TextStyle(fontSize: 10))),
                                Expanded(flex: 1,
                                    child: Text(_getEvaluationText(
                                        record['newAttendanceNote']),
                                        style: const TextStyle(fontSize: 10))),
                                const Expanded(flex: 1,
                                    child: Icon(Icons.comment_bank_outlined,
                                        color: kPrimaryBlue, size: 18)),
                              ],
                            ),
                          ),
                        ),
                        // تعديل الـ height لـ null وتغيير الـ Column بداخل الـ AnimatedContainer
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: isExpanded ? null : 0,
                          // إزالة القيمة الثابتة لحل الـ overflow
                          width: double.infinity,
                          color: kSecondaryBlue.withOpacity(0.4),
                          child: isExpanded
                              ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                    Icons.info_outline, color: kPrimaryBlue,
                                    size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    mainAxisSize: MainAxisSize.min,
                                    // مهم جداً هنا
                                    children: [
                                      Text("تعليق المعلم: ${record['note'] ??
                                          'لا يوجد تعليق'}",
                                          style: const TextStyle(fontSize: 12,
                                              color: kPrimaryBlue,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("التقييم: ${record['points'] ??
                                          0} نقاط", style: const TextStyle(
                                          fontSize: 11, color: kTextDark)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.close, color: kDangerRed, size: 16),
                                  onPressed: () =>
                                      setState(() => expandedRowIndex = null),
                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, IconData icon, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: kPrimaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryBlue))
          ]),
          const Divider(height: 25),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(
              color: kTextDark, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildWebSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(children: [
          const SizedBox(height: 60),
          Image.asset('assets/full_logo.png', height: 90,
              errorBuilder: (c, e, s) =>
              const Icon(Icons.school, size: 70, color: kPrimaryBlue)),
          const SizedBox(height: 20),
          Text(studentFullData?['name'] ?? "اسم الطالب", style: const TextStyle(
              fontWeight: FontWeight.bold, color: kPrimaryBlue)),
          const Divider(height: 40),
          _drawerItem(0, Icons.person_outline, "البيانات الشخصية"),
          _drawerItem(
              1, Icons.calendar_today_outlined, "حضور و غياب للمستوى الحالي"),
          _drawerItem(2, Icons.book_outlined, "مقررات المستوي"),
          _drawerItem(3, Icons.assignment_outlined, "أعمال الطالب"),
          _drawerItem(4, Icons.quiz_outlined, "الاختبارات"),
          const Spacer(),
          _drawerItem(5, Icons.logout, "تسجيل الخروج", isLogout: true),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title,
      {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: kSecondaryBlue,
      leading: Icon(icon, color: isLogout ? kDangerRed : (isSelected
          ? kPrimaryBlue
          : kLabelGrey)),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? kDangerRed : (isSelected
              ? kPrimaryBlue
              : kTextDark),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      onTap: () {
        if (isLogout) {
          _forceLogout();
        } else {
          Navigator.pop(context); // إغلاق الدرور
          setState(() => _selectedIndex = index);

          // تشغيل أنيميشن الانتقال بين الصفحات
          _pageAnimationController.reset();
          _pageAnimationController.forward();

          // جلب البيانات بناءً على التبويب المختار
          String studentId = studentFullData?['id']?.toString() ?? "";

          if (index == 1) {
            _fetchAttendance(studentId);
          } else if (index == 4) {
            _fetchExams(studentId); // استدعاء دالة جلب الاختبارات الجديدة
          }
        }
      },
    );
  }
}