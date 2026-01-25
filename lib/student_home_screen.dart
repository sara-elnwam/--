import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'student_exams_widget.dart';
import 'student_courses_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';

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
  late Animation<Offset> _slideAnimation;

  List<dynamic> examsList = [];
  bool _isExamsLoading = false;
  List<dynamic> coursesList = [];
  bool _isCoursesLoading = false;

  // قائمة أعمال الطالب وحالة التحميل
  List<dynamic> studentTasksList = [];
  bool _isTasksLoading = false;

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _loadInitialData();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  // --- دالات المساعدة ---
  String _getEvaluationText(dynamic value) {
    if (value == null) return "---";
    int? score = int.tryParse(value.toString());
    if (score == 1) return "ممتاز";
    if (score == 2) return "جيد جداً";
    if (score == 3) return "جيد";
    if (score == 4) return "مقبول";
    return "---";
  }

  String _getDayName(int dayNumber) {
    const days = {1: "السبت", 2: "الأحد", 3: "الإثنين", 4: "الثلاثاء", 5: "الأربعاء", 6: "الخميس", 7: "الجمعة"};
    return days[dayNumber] ?? "";
  }

  // --- جلب البيانات ---
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

  // دالة جلب أعمال الطالب - مُحدثة لمعالجة الـ null
  Future<void> _fetchStudentTasks() async {
    setState(() => _isTasksLoading = true);
    try {
      String stId = studentFullData?['id']?.toString() ?? "";
      String levelId = studentFullData?['levelId']?.toString() ?? "1";
 final url = '$baseUrl/Student/GetAllTasksBsedOnType?stId=$stId&levelId=$levelId&typeId=2';
      debugPrint("جاري الاتصال بالرابط: $url");

      final response = await http.get(Uri.parse(url));

      debugPrint("كود استجابة أعمال الطالب: ${response.statusCode}");
      debugPrint("البيانات المستلمة: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          // حل مشكلة الـ null: إذا كانت الـ data فارغة في السيرفر نجعل القائمة فارغة في التطبيق
          studentTasksList = responseData['data'] != null ? responseData['data'] as List : [];
        });
      }
    } catch (e) {
      debugPrint("حدث خطأ أثناء جلب المهام: $e");
    } finally {
      if (mounted) setState(() => _isTasksLoading = false);
    }
  }

  // دالة رفع الملفات (Upload File) المرتبطة بالزر
  Future<void> _uploadTaskFile(int taskId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("جاري رفع الملف..."), duration: Duration(seconds: 2)),
        );

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/Student/UploadTask'),
        );

        request.fields['StudentId'] = studentFullData?['id']?.toString() ?? "";
        request.fields['TaskId'] = taskId.toString();

        request.files.add(await http.MultipartFile.fromPath(
          'File',
          file.path,
          contentType: MediaType('application', 'octet-stream'),
        ));

        var response = await request.send();
        var responseData = await response.stream.bytesToString();

        debugPrint("استجابة الرفع: $responseData");

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم رفع الملف بنجاح"), backgroundColor: kSuccessGreen),
          );
          _fetchStudentTasks();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("فشل الرفع من السيرفر"), backgroundColor: kDangerRed),
          );
        }
      }
    } catch (e) {
      debugPrint("خطأ في الرفع: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء اختيار أو رفع الملف"), backgroundColor: kDangerRed),
      );
    }
  }

  Future<void> _fetchExams(String id) async {
    setState(() => _isExamsLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/Student/GetExam?id=$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          examsList = responseData['data'] != null ? [responseData['data']] : [];
        });
      }
    } catch (e) { debugPrint("Exams Error: $e"); }
    finally { if (mounted) setState(() => _isExamsLoading = false); }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isCoursesLoading = true);
    try {
      String stId = studentFullData?['id']?.toString() ?? "";
      String levelId = studentFullData?['levelId']?.toString() ?? "1";
      final url = '$baseUrl/Student/GetAllTasksBsedOnType?Stid=$stId&Levelid=$levelId&Typeid=3';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() { coursesList = responseData['data'] ?? []; });
      }
    } catch (e) { debugPrint("Courses Error: $e"); }
    finally { if (mounted) setState(() => _isCoursesLoading = false); }
  }

  Future<void> _fetchAttendance(String id) async {
    setState(() => _isAttendanceLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/Student/GetAttendaceByStudentId?id=$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() { attendanceList = responseData['data'] ?? []; });
      }
    } catch (e) { debugPrint("Attendance Error: $e"); }
    finally { if (mounted) setState(() => _isAttendanceLoading = false); }
  }

  void _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
    }
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
            position: _slideAnimation,
            child: _getPage(_selectedIndex),
          ),
        ),
      ),
    );
  }

  final List<String> _titles = ["البيانات الشخصية", "حضور و غياب للمستوي الحالي", "مقررات المستوي", "أعمال الطالب", "الاختبارات"];

  Widget _getPage(int index) {
    switch (index) {
      case 0: return _buildProfileTab();
      case 1: return _buildAttendanceTab();
      case 2: return StudentCoursesWidget(coursesList: coursesList, isLoading: _isCoursesLoading);
      case 3: return _buildStudentTasksTab();
      case 4: return StudentExamsWidget(examsList: examsList, isLoading: _isExamsLoading);
      default: return const Center(child: Text("قيد التطوير"));
    }
  }

  Widget _buildStudentTasksTab() {
    if (_isTasksLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));

    if (studentTasksList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 80, color: kLabelGrey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text("لا توجد مهام أو أعمال مطلوبة منك حالياً",
                style: TextStyle(color: kLabelGrey, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: studentTasksList.length,
      itemBuilder: (context, index) {
        final task = studentTasksList[index];
        // التأكد من وجود تسليم سابق
        final hasSubmitted = (task['studentExams'] != null && (task['studentExams'] as List).isNotEmpty) &&
            task['studentExams'][0]['url'] != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: kBorderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(task['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPrimaryBlue))),
                  if (task['mandatory'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kDangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: const Text("إلزامي", style: TextStyle(color: kDangerRed, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task['description'] ?? "", style: const TextStyle(color: kTextDark, fontSize: 13)),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: kLabelGrey),
                  const SizedBox(width: 4),
                  Text(hasSubmitted ? "تم التسليم بنجاح" : "لم يتم التسليم بعد",
                      style: TextStyle(color: hasSubmitted ? kSuccessGreen : kLabelGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _uploadTaskFile(task['id']),
                    icon: Icon(hasSubmitted ? Icons.edit : Icons.upload_file, size: 16),
                    label: Text(hasSubmitted ? "تعديل الرفع" : "رفع الملف"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSubmitted ? Colors.orange : kPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final data = studentFullData;
    final loc = data?['loc'];
    final group = data?['group'];
    final level = data?['level'];

    String sessionTimes = "غير محدد";
    if (group?['groupSessions'] != null) {
      List sessions = group['groupSessions'];
      sessionTimes = sessions.map((s) => "${_getDayName(s['day'] ?? 0)} ${s['hour'] ?? ""}").join(" - ");
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        _buildInfoBox("بيانات الطالب", Icons.person_outline, [
          _infoRow("اسم الطالب :", data?['name'] ?? "---"),
          _infoRow("كود الطالب :", data?['id']?.toString() ?? "---"),
          _infoRow("المكتب التابع له :", loc?['name'] ?? "---"),
          _infoRow("موعد الالتحاق بالمدرسة :", data?['joinDate']?.toString().split('T')[0] ?? "---"),
          _infoRow("اسم المدرسة الحكومية :", data?['governmentSchool'] ?? "---"),
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
    if (_isAttendanceLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
    if (attendanceList.isEmpty) return const Center(child: Text("لا توجد بيانات حضور"));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Center(child: Text('موعد الحلقة', style: _headerStyle))),
                  Expanded(flex: 2, child: Center(child: Text('الحضور', style: _headerStyle))),
                  Expanded(flex: 2, child: Center(child: Text('حفظ قديم', style: _headerStyle))),
                  Expanded(flex: 2, child: Center(child: Text('حفظ جديد', style: _headerStyle))),
                  Expanded(flex: 2, child: Center(child: Text('التعليق', style: _headerStyle))),
                ],
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = attendanceList[index];
                bool isExpanded = _expandedIndex == index;
                bool isPresent = record['isPresent'] ?? false;
                String dateRaw = record['createDate'] ?? "";

                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
                        color: isExpanded ? kSecondaryBlue.withOpacity(0.5) : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Column(children: [Text(_getDayNameFromDate(dateRaw), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(_formatSimpleDate(dateRaw), style: const TextStyle(fontSize: 10, color: Colors.grey))])),
                            Expanded(flex: 2, child: Center(child: Text(isPresent ? "حضور" : "غياب", style: TextStyle(color: isPresent ? kSuccessGreen : kDangerRed, fontWeight: FontWeight.bold, fontSize: 12)))),
                            Expanded(flex: 2, child: Center(child: Text(_getEvaluationText(record['oldAttendanceNote']), style: const TextStyle(fontSize: 12)))),
                            Expanded(flex: 2, child: Center(child: Text(_getEvaluationText(record['newAttendanceNote']), style: const TextStyle(fontSize: 12)))),
                            Expanded(flex: 2, child: Center(child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.chat_bubble_outline, size: 20, color: isExpanded ? kDangerRed : kPrimaryBlue))),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFFF1F5F9),
                        child: Text("تعليق المعلم : ${record['note'] ?? 'لا يوجد'}"),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getDayNameFromDate(String? dateStr) {
    if (dateStr == null) return "";
    DateTime date = DateTime.parse(dateStr);
    const days = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"];
    return days[date.weekday % 7];
  }

  String _formatSimpleDate(String? dateStr) {
    if (dateStr == null) return "";
    DateTime date = DateTime.parse(dateStr);
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  TextStyle get _headerStyle => const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPrimaryBlue);

  Widget _buildInfoBox(String title, IconData icon, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: kPrimaryBlue, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryBlue))]),
        const Divider(height: 20),
        ...rows,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 12)), const SizedBox(width: 6), Expanded(child: Text(value, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.w600, fontSize: 12)))]),
    );
  }

  Widget _buildWebSidebar() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/full_logo.png', height: 80, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 60, color: kPrimaryBlue)),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(studentFullData?['name'] ?? "اسم الطالب", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 14)),
              ),
              const Divider(height: 30),
              _drawerItem(0, Icons.person_outline, "البيانات الشخصية"),
              _drawerItem(1, Icons.calendar_today_outlined, "حضور و غياب للمستوى الحالي"),
              _drawerItem(2, Icons.book_outlined, "مقررات المستوي"),
              _drawerItem(3, Icons.assignment_outlined, "أعمال الطالب"),
              _drawerItem(4, Icons.quiz_outlined, "الاختبارات"),
              const Divider(),
              _drawerItem(5, Icons.logout, "تسجيل الخروج", isLogout: true),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title, {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: kSecondaryBlue,
      leading: Icon(icon, color: isLogout ? kDangerRed : (isSelected ? kPrimaryBlue : kLabelGrey)),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? kDangerRed : (isSelected ? kPrimaryBlue : kTextDark),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      onTap: () {
        if (isLogout) {
          _forceLogout();
        } else {
          Navigator.pop(context);
          if (_selectedIndex != index) {
            setState(() => _selectedIndex = index);
            _pageAnimationController.reset();
            _pageAnimationController.forward();
            String studentId = studentFullData?['id']?.toString() ?? "";
            if (index == 1) _fetchAttendance(studentId);
            else if (index == 2) _fetchCourses();
            else if (index == 3) _fetchStudentTasks();
            else if (index == 4) _fetchExams(studentId);
          }
        }
      },
    );
  }
}