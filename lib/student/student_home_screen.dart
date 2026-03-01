import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'student_exams_widget.dart';
import 'student_courses_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
const Color kPrimaryBlue = Color(0xFF07427C);
const Color kSecondaryBlue = Color(0xFFEBF4FF);
const Color kTextDark = Color(0xFF2E3542);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);
const Color kSuccessGreen = Color(0xFF16A34A);
const Color kDangerRed = Color(0xFFDC2626);
const Color kHeaderBg = Color(0xFFF8FAFC);
const Color kAccentOrange = Color(0xFFF59E0B);
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
  String? token;
  List<dynamic> studentTasksList = [];
  bool _isFileUploaded = false;
  bool _isAnswerSubmitted = false;
  bool _isTasksLoading = false;
  String? _taskErrorMessage;
  final TextEditingController _answerController = TextEditingController();
  int? _expandedIndex;
  List<File> _pendingFiles = [];
  List<String> _pendingFileNames = [];
  Map<String, dynamic>? _pendingTask;
  // IDs محفوظة محلياً - بتفضل حتى بعد إغلاق التطبيق
  Set<int> _answeredTaskIds = {};
  Set<int> _uploadedTaskIds = {};

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
    // تشغيل الأنيميشن تلقائياً عند أول دخول للشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  // ── تحميل الـ IDs المحفوظة من SharedPreferences عند فتح التطبيق ──
  Future<void> _loadSavedTaskIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String studentId = studentFullData?['id']?.toString() ?? '';
    final List<String> answered = prefs.getStringList('answered_tasks_$studentId') ?? [];
    final List<String> uploaded = prefs.getStringList('uploaded_tasks_$studentId') ?? [];
    if (mounted) {
      setState(() {
        _answeredTaskIds = answered.map((e) => int.tryParse(e) ?? -1).toSet();
        _uploadedTaskIds = uploaded.map((e) => int.tryParse(e) ?? -1).toSet();
      });
    }
  }

  // ── حفظ ID السؤال المجاوب ──
  Future<void> _saveAnsweredTaskId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String studentId = studentFullData?['id']?.toString() ?? '';
    final List<String> current = prefs.getStringList('answered_tasks_$studentId') ?? [];
    if (!current.contains(id.toString())) {
      current.add(id.toString());
      await prefs.setStringList('answered_tasks_$studentId', current);
    }
    if (mounted) setState(() => _answeredTaskIds.add(id));
  }

  // ── حفظ ID البحث المرفوع ──
  Future<void> _saveUploadedTaskId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final String studentId = studentFullData?['id']?.toString() ?? '';
    final List<String> current = prefs.getStringList('uploaded_tasks_$studentId') ?? [];
    if (!current.contains(id.toString())) {
      current.add(id.toString());
      await prefs.setStringList('uploaded_tasks_$studentId', current);
    }
    if (mounted) setState(() => _uploadedTaskIds.add(id));
  }

  Future<void> testAllEndpoints() async {
    String stId = studentFullData?['id']?.toString() ?? "5";
    String levelId = studentFullData?['levelId']?.toString() ?? "1";

    List<Map<String, String>> endpoints = [
      {'name': 'Profile', 'url': '$baseUrl/Student/GetById?id=$stId'},
      {'name': 'Attendance', 'url': '$baseUrl/Student/GetAttendaceByStudentId?id=$stId'},
      {'name': 'Tasks (Type 1)', 'url': '$baseUrl/Student/GetAllTasksBsedOnType?stId=$stId&levelId=$levelId&typeId=1'},
      {'name': 'Tasks (Type 2)', 'url': '$baseUrl/Student/GetAllTasksBsedOnType?stId=$stId&levelId=$levelId&typeId=2'},
      {'name': 'Exams', 'url': '$baseUrl/Student/GetExam?id=$stId'},
    ];

    print("--- 🔍 Testing Endpoints Status ---");
    for (var ep in endpoints) {
      try {
        final res = await http.get(Uri.parse(ep['url']!));
        print(" ${ep['name']}: Status ${res.statusCode} | Data: ${res.body.substring(0, res.body.length > 50 ? 50 : res.body.length)}...");
      } catch (e) {
        print(" ${ep['name']}: Failed | Error: $e");
      }
    }
    print("-----------------------------------");
  }

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
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = widget.loginData?['token']?.toString() ?? prefs.getString('user_token');

    // ← الحل: السيرفر بيرجع userId (رقمي) مباشرة في الـ response
    // مثال: {"userId":4,"userType":0,"user_Id":"5bf6a1c9-..."}
    String? numericId = widget.loginData?['userId']?.toString() ?? prefs.getString('user_id');

    debugPrint("DEBUG: numericId from loginData: $numericId");

    // لو لقيناه مباشرة، بنروح للـ GetById فوراً بدون أي بحث
    if (numericId != null && numericId.isNotEmpty && numericId != "0" && numericId != "null") {
      await prefs.setString('student_id', numericId);
      await _fetchStudentProfile(numericId, token);
      return;
    }

    // fallback: لو ملقناش، نبحث في GetAll بالـ GUID
    String? savedGuid = widget.loginData?['user_Id']?.toString() ?? prefs.getString('user_guid');
    debugPrint("DEBUG: Fallback - searching by GUID: $savedGuid");

    try {
      final allResponse = await http.get(
        Uri.parse('$baseUrl/Student/GetAll'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
      );

      if (allResponse.statusCode == 200) {
        final List<dynamic> allStudents = jsonDecode(allResponse.body)['data'] ?? [];

        dynamic matched;

        // بحث بالـ GUID
        if (savedGuid != null && savedGuid.isNotEmpty) {
          matched = allStudents.firstWhere(
                (s) =>
            s['user_Id']?.toString() == savedGuid ||
                s['userId']?.toString() == savedGuid ||
                s['guid']?.toString() == savedGuid,
            orElse: () => null,
          );
        }

        // بحث بالتليفون
        if (matched == null) {
          String? savedPhone = prefs.getString('user_phone');
          if (savedPhone != null && savedPhone.isNotEmpty) {
            matched = allStudents.firstWhere(
                  (s) => s['phone']?.toString().trim() == savedPhone.trim(),
              orElse: () => null,
            );
          }
        }

        if (matched != null) {
          String foundId = matched['id'].toString();
          debugPrint("DEBUG: Found student ID via GetAll: $foundId");
          await prefs.setString('student_id', foundId);
          await _fetchStudentProfile(foundId, token);
        } else {
          debugPrint("DEBUG: Student not found anywhere!");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("DEBUG: Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _fetchStudentProfile(String id, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Student/GetById?id=$id'),
        headers: { if (token != null) 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          studentFullData = data['data'];
          _isLoading = false;
        });

        _fetchAttendance(id);
        _fetchCourses();
        _fetchStudentTasks();
        _loadSavedTaskIds(); // تحميل الـ IDs المحفوظة محلياً

      } else if (response.statusCode == 400 && id.contains('-')) {
        // لو الـ ID GUID وفشل، بنحاول ننقذ الموقف بالبحث
        _rescueByUserName(token);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error in Fetch Profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _rescueByUserName(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Student/GetAll'),
        headers: { if (token != null) 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allStudents = jsonDecode(response.body)['data'] ?? [];

        // 1. البيانات اللي معانا من اللوجن
        String targetPhone = widget.loginData?['phoneNumber']?.toString().trim() ?? "";
        String targetName = widget.loginData?['userName']?.toString().toLowerCase().trim() ?? "";

        dynamic matchedStudent;

        // 2. المحاولة الأولى: البحث برقم التليفون (أدق حاجة)
        matchedStudent = allStudents.firstWhere(
              (s) => s['phoneNumber']?.toString().trim() == targetPhone,
          orElse: () => null,
        );

        // 3. المحاولة الثانية: لو ملقاش، ندور بالاسم في كل مكان (userName أو حتى لو مكتوب في الـ group)
        if (matchedStudent == null) {
          matchedStudent = allStudents.firstWhere(
                (s) {
              String sName = (s['userName'] ?? "").toString().toLowerCase();
              // بنشوف لو الاسم موجود في أي حقل نصي جوه بيانات الطالب
              return (sName.isNotEmpty && sName.contains(targetName)) ||
                  s.toString().toLowerCase().contains(targetName);
            },
            orElse: () => null,
          );
        }

        // 4. لو ملقاش — نوقف التحميل ونظهر خطأ بدل ما ناخد أول طالب
        if (matchedStudent == null) {
          debugPrint("DEBUG: Could not find student - no fallback used");
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        if (matchedStudent != null) {
          String realId = matchedStudent['id'].toString();

          setState(() {
            // 1. تحديث الكائن الأساسي
            studentFullData = matchedStudent;

            // 2. "تسكين" البيانات في المتغيرات اللي الشاشة بتعرضها
            // لو عندك متغيرات زي studentName أو studentCode، حدثيها هنا
            // مثال:
            // studentName = matchedStudent['name'] ?? matchedStudent['userName'] ?? "---";

            _isLoading = false;
          });

          // 3. الخطوة الأهم: نطلب البروفايل الكامل بالـ ID اللي لقيناه
          // ده هيجيب الحقول الناقصة (زي المدرسة، المستوى، إلخ) لو موجودة للسيرفر
          _fetchStudentProfile(realId, token);
        }
      }
    } catch (e) {
      debugPrint("Rescue Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }
// دالة مساعدة لحفظ البيانات وتشغيل بقية الشاشات
  void _setupStudentData(Map<String, dynamic> data) async {
    String numericId = data['id'].toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_id', numericId);

    if (mounted) {
      setState(() {
        studentFullData = data;
        _isLoading = false;
      });
      // تشغيل جلب الحضور بالـ ID الصحيح (5 مثلاً)
      _fetchAttendance(numericId);
    }
  }
// دالة مساعدة لتنظيم الكود ومنع التكرار
  void _handleSuccessfulProfile(Map<String, dynamic> data) async {
    String numericId = data['id'].toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_id', numericId);

    if (mounted) {
      setState(() {
        studentFullData = data;
        _isLoading = false;
      });
      // هنا بنطلب الحضور بالـ ID الرقمي الصح (5 مثلاً) فالداتا تظهر
      _fetchAttendance(numericId);
    }
  }
  void _processProfileData(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      studentFullData = data;
      _isLoading = false;
    });
    debugPrint("DEBUG: UI Updated with Student ID: ${data['id']}");
  }

  Future<void> _fetchStudentTasks() async {
    if (!mounted) return;
    // مسح الداتا القديمة فوراً قبل جلب الجديدة — يمنع ظهور بيانات قديمة
    setState(() {
      _isTasksLoading = true;
      studentTasksList = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');

      String stId = studentFullData?['id']?.toString() ?? "5";
      String levelId = studentFullData?['levelId']?.toString() ?? "1";

      final url = Uri.parse('$baseUrl/Student/GetAllTasksBsedOnType?Stid=$stId&Levelid=$levelId&TypeId=-3');

      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      debugPrint("📡 Fetching from: $url");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> tasks = decoded['data'] ?? [];

        // DEBUG: طباعة تفاصيل كل task للتشخيص
        debugPrint("🔍 All tasks breakdown:");
        for (final t in tasks) {
          debugPrint("  ID=${t['id']} typeId=${t['typeId']} name=${t['name']} exams=${(t['studentExams'] as List? ?? []).length}");
        }

        setState(() {
          studentTasksList = tasks;
          _taskErrorMessage = studentTasksList.isEmpty ? "لا يوجد أعمال حالية" : null;
        });
        debugPrint(" Tasks Loaded: ${studentTasksList.length} items");
      }
    } catch (e) {
      debugPrint(" Error: $e");
    } finally {
      if (mounted) setState(() => _isTasksLoading = false);
    }
  }
  Future<void> _updateStudentProfile() async {
    if (studentFullData == null) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');

      Map<String, dynamic> body = {
        "id": studentFullData!['id'],
        "name": studentFullData!['name'],
        "phone": studentFullData!['phone'],
        "address": studentFullData!['address'],
        "parentJob": studentFullData!['parentJob'] ?? "",
        "governmentSchool": studentFullData!['governmentSchool'] ?? "",
        "attendanceType": studentFullData!['attendanceType'] ?? "",
        "birthDate": studentFullData!['birthDate'] ?? DateTime.now().toIso8601String(),
        "locId": studentFullData!['locId'] ?? 0,
        "phone2": studentFullData!['phone2'] ?? "",
        "groupId": studentFullData!['groupId'] ?? 0,
        "levelId": studentFullData!['levelId'] ?? 0,
        "joinDate": studentFullData!['joinDate'] ?? DateTime.now().toIso8601String(),
        "paymentType": studentFullData!['paymentType'] ?? "",
        "documentType": studentFullData!['documentType'] ?? "",
        "typeInfamily": studentFullData!['typeInfamily'] ?? "",
        "loc": studentFullData!['loc'],
        "group": studentFullData!['group'],
        "level": studentFullData!['level'],
      };

      final response = await http.put(
        Uri.parse('$baseUrl/Student/Update'),
        headers: {
          'accept': 'text/plain',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint(" Update Successful");
        _fetchStudentProfile(studentFullData!['id'].toString(), token);
      } else {
        debugPrint(" Update Failed: ${response.body}");
      }
    } catch (e) {
      debugPrint(" Update Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Widget _buildNoUploadsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40), // زيادة الطول ليكون مثل الويب
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: const Center(
        child: Text(
          "لا يوجد واجبات تطلب رفع ملفات الان",
          style: TextStyle(color: Color(0xFF2E3542), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  Future<void> _submitTaskAnswer(Map<String, dynamic> task) async {
    // 1. التأكد من أن الطالب كتب نصاً قبل الإرسال
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠ يرجى كتابة الإجابة أولاً"))
      );
      return;
    }

    setState(() => _isTasksLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('user_token');

      // 2. تجهيز البارامترات المطلوبة للـ API
      final queryParams = {
        'examId': task['id'].toString(), // ← مهم جداً عشان السيرفر يعرف يحفظ على أي سؤال
        'levelId': task['levelId'].toString(),
        'typeId': task['typeId'].toString(),
        'stId': studentFullData?['id']?.toString() ?? "5",
        'note': _answerController.text,
      };

      // 3. بناء الرابط النهائي كما في الـ Swagger
      final uri = Uri.parse('https://nour-al-eman.runasp.net/api/StudentCources/UploadStudentExamWithNoFile')
          .replace(queryParameters: queryParams);

      debugPrint("📡 Submitting to: $uri");

      final response = await http.post(
        uri,
        headers: {
          'accept': 'text/plain',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      // 4. معالجة الرد وتحديث واجهة الموبايل
      if (response.statusCode == 200) {
        _answerController.clear();
        // بعد النجاح: refresh من السيرفر مباشرة — السيرفر هو المرجع
        // السيرفر هيرجع studentExams ممليانة فالسؤال هيختفي تلقائياً
        await _fetchStudentTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ تم حفظ الإجابة بنجاح"), backgroundColor: Colors.green),
          );
        }
      } else {
        debugPrint(" Server Error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("فشل الحفظ: ${response.statusCode}"))
        );
      }
    } catch (e) {
      debugPrint("️ Global Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ في الاتصال بالسيرفر"))
      );
    } finally {
      if (mounted) {
        setState(() => _isTasksLoading = false);
      }
    }
  }
  Widget _buildSuccessMessageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: const Text(
        "لقد أجبت على سؤال هذا الاسبوع بنجاح\nانتظر حتى يتم رفع سؤال اخر",
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF27AE60), fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
      ),
    );
  }
  Widget _buildTaskHeaderCard(Map<String, dynamic> task) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // تكبير الكارت
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        // لتبديل مكان الأيقونة والنص حسب اللغة
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // معلومات المهمة
          Expanded(
            child: Column(
              crossAxisAlignment: isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.start,
              children: [
                Text(
                  "الإسم: ${task['name']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "التفاصيل: ${task['description']}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
// داخل دالة _buildTaskHeaderCard
          InkWell(
            onTap: () => _handlePickFile(task: task),
            child: Row(
              children: [
                Text(
                  isArabic ? "رفع الملف" : "Upload File",
                  style: const TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.upload_outlined, color: Color(0xFFD35400), size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _handlePickFile({Map<String, dynamic>? task}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowMultiple: true,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg', 'docx'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pendingFiles = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
          _pendingFileNames = result.files.map((f) => f.name).toList();
          _pendingTask = task;
        });
        _showUploadConfirmDialog();
      }
    } catch (e) { debugPrint("File Pick Error: $e"); }
  }

  void _showUploadConfirmDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: kPrimaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.upload_file_outlined, color: kPrimaryBlue, size: 32)),
                const SizedBox(height: 16),
                Text(_pendingFiles.length == 1 ? "تأكيد رفع الملف" : "تأكيد رفع ${_pendingFiles.length} ملفات",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true, itemCount: _pendingFileNames.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: kBorderColor),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        const Icon(Icons.insert_drive_file_outlined, color: kPrimaryBlue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_pendingFileNames[i],
                            style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_pendingFiles.length == 1 ? "هل تريد رفع هذا الملف؟" : "هل تريد رفع هذه الملفات؟",
                    style: const TextStyle(color: kLabelGrey, fontSize: 13)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () {
                      setState(() { _pendingFiles = []; _pendingFileNames = []; _pendingTask = null; });
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text("إلغاء", style: TextStyle(color: kLabelGrey, fontWeight: FontWeight.bold)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () { Navigator.pop(ctx); _uploadConfirmedFiles(); },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text("تأكيد الرفع", style: TextStyle(fontWeight: FontWeight.bold)),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadConfirmedFiles() async {
    if (_pendingFiles.isEmpty) return;
    setState(() => _isTasksLoading = true);
    final filesToUpload = List<File>.from(_pendingFiles);
    final taskSnapshot = _pendingTask;
    setState(() { _pendingFiles = []; _pendingFileNames = []; _pendingTask = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      final stId = studentFullData?['id']?.toString() ?? "5";
      final levelId = studentFullData?['levelId']?.toString() ?? "1";
      final typeId = taskSnapshot?['typeId']?.toString() ?? "2";
      int successCount = 0;
      // نرفع ملف واحد بس (أول ملف) — السيرفر بيرفض التكرار
      final examId = taskSnapshot?['id']?.toString() ?? '';
      final file = filesToUpload.first;
      final uri = Uri.parse('https://nour-al-eman.runasp.net/api/StudentCources/UploadStudentExam')
          .replace(queryParameters: {
        'levelId': levelId,
        'typeId': typeId,
        'stId': stId,
        'examId': examId,
      });
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = '*/*';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await http.Response.fromStream(await request.send());
      debugPrint("Upload ${response.statusCode}: ${response.body}");
      // السيرفر بيرد 200 حتى لو في error في الـ body — نتحقق من "Done"
      final responseBody = response.body;
      if (response.statusCode == 200 && responseBody.contains('Done')) {
        successCount = 1;
      } else if (response.statusCode == 200 && !responseBody.contains('error')) {
        successCount = 1;
      }
      if (mounted) {
        if (successCount > 0) {
          if (taskSnapshot != null) {
            await _saveUploadedTaskId(taskSnapshot['id'] ?? -1);
          }
          _fetchStudentTasks();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("✅ تم رفع $successCount ملف بنجاح"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ فشل رفع الملفات"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء الرفع"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isTasksLoading = false);
    }
  }

  Widget _buildStudentTasksTab() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // typeId=2: أبحاث — نفس منطق السؤال الأسبوعي بالظبط
    // خد أحدث بحث واحد بس (أعلى ID من كل الأبحاث)
    // لو الأحدث اترفع (exams > 0) → اعرض "لا يوجد واجبات"
    // لو الأحدث لم يترفع (exams = 0) → اعرضه للطالب
    final allResearch = studentTasksList.where((t) => t['typeId'] == 2).toList();

    final latestResearch = allResearch.isNotEmpty
        ? allResearch.reduce((a, b) => (a['id'] ?? 0) > (b['id'] ?? 0) ? a : b)
        : null;

    final bool latestResearchUploaded = latestResearch == null
        || (latestResearch['studentExams'] as List? ?? []).isNotEmpty;

    // للعرض: لو في بحث جديد لم يترفع، اعرضه — غير كده فاضي
    final pendingResearch = (latestResearch != null && !latestResearchUploaded)
        ? [latestResearch]
        : <dynamic>[];

    // typeId=1: السؤال الأسبوعي — أحدث سؤال واحد بس (أعلى ID)
    final allWeekly = studentTasksList.where((t) => t['typeId'] == 1).toList();
    final latestWeekly = allWeekly.isNotEmpty
        ? allWeekly.reduce((a, b) => (a['id'] ?? 0) > (b['id'] ?? 0) ? a : b)
        : null;
    final bool latestWeeklyAnswered = latestWeekly == null
        || (latestWeekly['studentExams'] as List? ?? []).isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel("الأبحاث", Icons.upload_file_outlined),
          const SizedBox(height: 10),
          if (pendingResearch.isEmpty)
            _buildNoUploadsCard()
          else
            ...pendingResearch.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildResearchTaskCard(task),
            )),
          const SizedBox(height: 24),
          _buildSectionLabel("السؤال الأسبوعي", Icons.help_outline),
          const SizedBox(height: 10),
          if (latestWeekly == null || latestWeeklyAnswered)
            _buildSuccessMessageCard()
          else
            _buildTaskAnswerCard(latestWeekly, isArabic ? TextAlign.right : TextAlign.left),
        ],
      ),
    );
  }
  Widget _buildTaskAnswerCard(Map<String, dynamic> task, TextAlign textAlign) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        // تجبر العناصر على التوجه لليمين في حالة العربي
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // الاسم (sara) - تم استخدامه لإجبار المحاذاة لليمين
          SizedBox(
            width: double.infinity,
            child: Text(
              task['name'] ?? "",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
          ),
          const SizedBox(height: 4),
          // الوصف (testquestion) - تم استخدامه لإجبار المحاذاة لليمين
          SizedBox(
            width: double.infinity,
            child: Text(
              task['description'] ?? "",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
          ),
          const SizedBox(height: 20),

          // صندوق النص المنحني
          TextField(
            controller: _answerController, // تأكدي من ربط الكنترول للإجابة
            maxLines: 8,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              hintText: isArabic ? "اكتب هنا..." : "...Write here",
              hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFFD35400), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // زر حفظ الإجابة (تصغير العرض والطول ووضعه في المنتصف)
          Center(
            child: SizedBox(
              width: 190, // تصغير العرض سيكا كمان
              height: 50, // تصغير الطول سيكا كمان ليصبح أنحف جداً
              child: ElevatedButton(
                onPressed: () => _submitTaskAnswer(task), // استخدام الدالة الفعلية للإرسال
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35400),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isArabic ? "حفظ الإجابة" : "Save Answer",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15, // تصغير الخط ليتناسب مع الحجم الجديد
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        print("تم اختيار ملف: ${file.name}");

        // هنا يمكنك إظهار رسالة نجاح للمستخدم
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم اختيار: ${file.name}")),
        );
      } else {
        // المستخدم أغلق نافذة الاختيار
        print("لم يتم اختيار أي ملف");
      }
    } catch (e) {
      print("خطأ أثناء اختيار الملف: $e");
    }
  }
  Future<void> _submitTask(int taskId) async {
    // هنا تضعين كود الـ API الخاص بحفظ الإجابة
    print("جاري حفظ الإجابة للمهمة رقم: $taskId");
  }


  // دوال الجلب الأخرى
  Future<void> _fetchExams(String id) async {
    setState(() => _isExamsLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/Student/GetExam?id=$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() { examsList = responseData['data'] != null ? [responseData['data']] : []; });
      }
    } catch (e) { debugPrint("Exams Error: $e"); }
    finally { if (mounted) setState(() => _isExamsLoading = false); }
  }

  Future<void> _fetchCourses() async {
    setState(() => _isCoursesLoading = true);
    try {
      String stId = studentFullData?['id']?.toString() ?? "";
      String levelId = studentFullData?['levelId']?.toString() ?? "1";
      final response = await http.get(Uri.parse('$baseUrl/Student/GetAllTasksBsedOnType?Stid=$stId&Levelid=$levelId&Typeid=3'));
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("تسجيل الخروج",
                style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold)),
            content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: kLabelGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDangerRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) =>  LoginScreen()),
                          (route) => false,
                    );
                  }
                },
                child: const Text("خروج"),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryBlue)));

    return Directionality(
      textDirection: Localizations.localeOf(context).languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
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

  Widget _buildProfileTab() {
    final data = studentFullData;
    if (data == null) return const Center(child: CircularProgressIndicator());

    final loc = data['loc'];
    final group = data['group'];
    final level = data['level'];

    // --- معالجة التاريخ (تعديل لضمان الدقة) ---
    String joinDateStr = data['joinDate']?.toString() ?? "";
    String displayJoinDate;

    // إذا كان التاريخ نل، فارغ، أو يحتوي على كلمة "null" نصية
    if (joinDateStr.isEmpty || joinDateStr == "null") {
      DateTime now = DateTime.now();
      displayJoinDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    } else {
      // محاولة قص التاريخ إذا كان بصيغة ISO (مثل 2024-05-20T00:00:00)
      displayJoinDate = joinDateStr.contains('T') ? joinDateStr.split('T')[0] : joinDateStr;
    }
    // معالجة مواعيد الحلقات
    String sessionTimes = "---";
    if (group != null && group['groupSessions'] != null) {
      List sessions = group['groupSessions'];
      if (sessions.isNotEmpty) {
        sessionTimes = sessions.map((s) {
          String dayName = _getDayName(int.tryParse(s['day']?.toString() ?? "0") ?? 0);
          String hour = s['hour']?.toString() ?? "---";
          return "$dayName ($hour)";
        }).join(" ، ");
      }
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        _buildInfoBox("بيانات الطالب", Icons.person_outline, [
          _infoRow("اسم الطالب :", data?['name'] ?? "---"),
          _infoRow("كود الطالب :", data?['id']?.toString() ?? "---"),
          _infoRow("المكتب التابع له :", loc?['name'] ?? "---"),
          _infoRow("موعد الالتحاق بالمدرسة :", displayJoinDate),
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
// دالة رسم الهيدر الأزرق مثل الويب
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18),
        textAlign: TextAlign.right, // لغة الويب تظهر العناوين يميناً
      ),
    );
  }

// دالة تظهر عند عدم وجود مهام
  Widget _buildNoTasksView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          _buildSuccessMessageCard(),
        ],
      ),
    );
  }
  Widget _buildAttendanceTab() {
    if (_isAttendanceLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
    if (attendanceList.isEmpty) return const Center(child: Text("لا توجد بيانات حضور"));

    bool isRtl = Directionality.of(context) == TextDirection.rtl;

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
                  Expanded(flex: 2, child: Container(
                      padding: EdgeInsets.only(right: isRtl ? 1 : 0, left: !isRtl ? 1 : 0),
                      child: Center(child: Text('الحضور', style: _headerStyle))
                  )),
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

                String teacherNote = record['note'] ?? "لا يوجد";
                String points = record['points']?.toString() ?? "0";

                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
                        color: isExpanded ? kSecondaryBlue.withOpacity(0.4) : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Column(children: [
                              Text(_getDayNameFromDate(dateRaw), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(_formatSimpleDate(dateRaw), style: const TextStyle(fontSize: 10, color: Colors.grey))
                            ])),
                            Expanded(flex: 2, child: Container(
                                padding: EdgeInsets.only(right: isRtl ? 1 : 0, left: !isRtl ? 1 : 0),
                                child: Center(child: Text(isPresent ? "حضور" : "غياب",
                                    style: TextStyle(color: isPresent ? kSuccessGreen : kDangerRed, fontWeight: FontWeight.bold, fontSize: 12)))
                            )),
                            Expanded(flex: 2, child: Center(child: Text(_getEvaluationText(record['oldAttendanceNote']), style: const TextStyle(fontSize: 12)))),
                            Expanded(flex: 2, child: Center(child: Text(_getEvaluationText(record['newAttendanceNote']), style: const TextStyle(fontSize: 12)))),
                            Expanded(flex: 2, child: Center(child: Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.chat_bubble_outline,
                                size: 20,
                                color: isExpanded ? kDangerRed : kPrimaryBlue))),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        color: kSecondaryBlue.withOpacity(0.2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("تعليق المعلم : ", style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Expanded(child: Text(teacherNote, style: const TextStyle(color: kTextDark, fontSize: 14))),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text("التقييم : ", style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text("$points نقاط", style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () => setState(() => _expandedIndex = null),
                                    child: const Text("إخفاء", style: TextStyle(color: kDangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Image.asset(
                      'assets/full_logo.png',
                      height: 80,
                      errorBuilder: (c, e, s) => const Icon(Icons.school, size: 60, color: kPrimaryBlue),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        studentFullData?['name'] ?? "اسم الطالب",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 14),
                      ),
                    ),
                    const Divider(height: 30),
                    _drawerItem(0, Icons.person_outline, "البيانات الشخصية"),
                    _drawerItem(1, Icons.calendar_today_outlined, "حضور و غياب للمستوى الحالي"),
                    _drawerItem(2, Icons.book_outlined, "مقررات المستوي"),
                    _drawerItem(3, Icons.assignment_outlined, "أعمال الطالب"),
                    _drawerItem(4, Icons.quiz_outlined, "الاختبارات"),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  Expanded(
                    child: Center(
                      child: _drawerItem(5, Icons.logout, "تسجيل الخروج", isLogout: true),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String title, {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? kSecondaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: isLogout ? kDangerRed : (isSelected ? kPrimaryBlue : kLabelGrey), size: 22),
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
            if (_selectedIndex != index) {
              // نحدث الـ state أولاً قبل إغلاق الدراور — يمنع الـ lag
              setState(() => _selectedIndex = index);
              _pageAnimationController.reset();
              _pageAnimationController.forward();
              String studentId = studentFullData?['id']?.toString() ?? "";
              if (index == 1) _fetchAttendance(studentId);
              else if (index == 2) _fetchCourses();
              else if (index == 3) _fetchStudentTasks();
              else if (index == 4) _fetchExams(studentId);
            }
            // إغلاق الدراور بعد تحديث الـ state مباشرةً
            Navigator.pop(context);
          }
        },
      ), // ListTile
    ); // AnimatedContainer
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: kBorderColor, thickness: 1.2)),
      ],
    );
  }

  Widget _buildResearchTaskCard(Map<String, dynamic> task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("الإسم: ${task['name'] ?? ''}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text("التفاصيل: ${task['description'] ?? ''}", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _handlePickFile(task: task),
            child: const Row(
              children: [
                Text("رفع الملف", style: TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.upload_outlined, color: Color(0xFFD35400), size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}