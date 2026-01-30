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
    await testAllEndpoints();
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
  Future<void> _fetchStudentTasks() async {
    if (!mounted) return;
    setState(() => _isTasksLoading = true);

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
        setState(() {
          studentTasksList = decoded['data'] ?? [];
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
        'levelId': task['levelId'].toString(),
        'typeId': task['typeId'].toString(),
        'stId': studentFullData?['id']?.toString() ?? "5",
        'note': _answerController.text, // النص المكتوب في الخانة
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
        setState(() {
          // هذا السطر هو المسؤول عن إخفاء صندوق الكتابة وإظهار كارت النجاح فوراً
          _isAnswerSubmitted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("تم حفظ الإجابة بنجاح"),
                backgroundColor: Colors.green
            )
        );

        // مسح النص بعد الإرسال الناجح
        _answerController.clear();
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
            onTap: () => _handlePickFile(), // تأكدي أنها _handlePickFile وليست _pickFile
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
  Future<void> _handlePickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'docx'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() => _isTasksLoading = true);

        final prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('user_token');

        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/Student/UploadTaskFile'));
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['stId'] = studentFullData?['id']?.toString() ?? "5";
        request.fields['taskId'] = studentTasksList.first['id'].toString();
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          setState(() {
            _isFileUploaded = true; // هذا السطر هو المسؤول عن تبديل الكارت العلوي فوراً
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم رفع الملف بنجاح"), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
    } finally {
      if (mounted) setState(() => _isTasksLoading = false);
    }
  }

  Widget _buildStudentTasksTab() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // فلترة المهام التي لم تحل (studentExams فارغة)
    final pendingTasks = studentTasksList.where((t) => (t['studentExams'] as List).isEmpty).toList();

    // إذا كانت المهام فارغة تماماً من السيرفر
    if (pendingTasks.isEmpty) {
      return _buildNoTasksView();
    }

    final activeTask = pendingTasks.first;
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // الكارت العلوي (رفع الملف)
          _isFileUploaded
              ? _buildNoUploadsCard() // يظهر هذا الكارت عند نجاح الرفع
              : _buildTaskHeaderCard(activeTask),

          const SizedBox(height: 20),

          // الكارت السفلي (الإجابة النصية)
          _isAnswerSubmitted
              ? _buildSuccessMessageCard() // يظهر هذا الكارت عند نجاح حفظ الإجابة
              : _buildTaskAnswerCard(activeTask, isArabic ? TextAlign.right : TextAlign.left),
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

  // --- UI: أعمال الطالب المطور كلياً ليطابق الصورة المرسلة ---

  // --- UI: البيانات الشخصية ---
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