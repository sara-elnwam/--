import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'session_model.dart'; // تأكد أن الملف موجود في مشروعك

class GroupDetailsDashboard extends StatefulWidget {
  final int groupId;
  final int levelId;
  final String groupName;

  const GroupDetailsDashboard({
    super.key,
    required this.groupId,
    required this.levelId,
    required this.groupName,
  });

  @override
  State<GroupDetailsDashboard> createState() => _GroupDetailsDashboardState();
}

class _GroupDetailsDashboardState extends State<GroupDetailsDashboard> {
  String _selectedSection = "الطلاب";
  final List<String> _sections = ["الطلاب", "تسجيل الحضور", "تصحيح الاختبارات"];
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final String url = 'https://nour-al-eman.runasp.net/api/Group/GetGroupDetails?GroupId=${widget.groupId}&LevelId=${widget.levelId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List rawStudents = jsonData["data"] is List ? jsonData["data"] : (jsonData["data"]["students"] ?? []);
        setState(() {
          _students = rawStudents.map((x) => Student.fromJson(x)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(widget.groupName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [_buildDropdown()],
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF07427C))) : _buildBodyContent(),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF07427C).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSection,
          items: _sections.map((String v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13, color: Color(0xFF07427C), fontWeight: FontWeight.bold)))).toList(),
          onChanged: (v) => setState(() => _selectedSection = v!),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedSection == "الطلاب") return _buildStudentsTable();
    return Center(child: Text("شاشة $_selectedSection قيد التطوير"));
  }

  Widget _buildStudentsTable() {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: const Row(
            children: [
              Expanded(child: Center(child: Text("الإسم", style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text("أبحاث", style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text("سؤال اسبوعي", style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text("بيانات", style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _students.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (c, i) {
              final s = _students[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Center(child: Text(s.name, style: const TextStyle(fontSize: 13)))),
                    Expanded(child: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF07427C)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => StudentExamsScreen(studentId: s.id, studentName: s.name))),
                    )),
                    Expanded(child: IconButton(
                      icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF07427C), size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => WeeklyQuestionsScreen(studentId: s.id, studentName: s.name))),
                    )),
                    Expanded(child: IconButton(
                      icon: const Icon(Icons.person, color: Color(0xFF07427C), size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => StudentProfileScreen(studentId: s.id))),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- شاشة بيانات الطالب المعدلة للمحاذاة الدقيقة ---
class StudentProfileScreen extends StatefulWidget {
  final int studentId;
  const StudentProfileScreen({super.key, required this.studentId});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }
// دالة ذكية لمعالجة التاريخ ومنع ظهور 1970-01-01
  String _formatDate(dynamic dateValue) {
    // 1. لو القيمة نل أو نص "null" أو فاضية، رجعي -- فوراً
    if (dateValue == null || dateValue.toString().isEmpty || dateValue.toString().toLowerCase() == "null") {
      return "--";
    }

    try {
      String dateStr = dateValue.toString();

      // 2. لو التاريخ راجع بقيمة صفرية أو بداية التقويم (التي تسبب ظهور 1970)
      if (dateStr.startsWith("0001") || dateStr.startsWith("1970")) {
        return "--";
      }

      // 3. قص التاريخ لأول 10 رموز فقط (YYYY-MM-DD)
      if (dateStr.contains("T")) {
        return dateStr.split("T")[0];
      }
      return dateStr;
    } catch (e) {
      return "--";
    }
  }
  Future<void> _fetchDetails() async {
    final url = "https://nour-al-eman.runasp.net/api/Student/GetById?id=${widget.studentId}";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _data = json.decode(res.body)["data"];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: const Text("البيانات الشخصية", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)))
            : _data == null
            ? const Center(child: Text("خطأ في تحميل البيانات"))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildInfoCard(
                title: "بيانات الطالب",
                icon: Icons.badge_outlined,
                rows: [
                  _buildDataRow("اسم الطالب :", _data!["name"] ?? "--"),
                  _buildDataRow("كود الطالب :", _data!["id"].toString()),
                  _buildDataRow("المكتب التابع له :", _data!["loc"]?["name"] ?? "--"),
                  _buildDataRow("اسم المدرسة الحكومية :", _data!["governmentSchool"] ?? "--"),
                  _buildDataRow("موعد الالتحاق :", _formatDate(_data!["joinDate"])),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                title: "المدرسة",
                icon: Icons.school_outlined,
                rows: [
                  _buildDataRow("مجموعة :", _data!["group"]?["name"] ?? "--"),
                  _buildDataRow("المستوى :", _data!["level"]?["name"] ?? "--"),
                  _buildDataRow("اسم المعلم :", _data!["group"]?["emp"]?["name"] ?? "--"),
                  _buildDataRow("الحضور :", _data!["attendanceType"]?.toString() ?? "--"), // هيقرأ "اونلاين" زي ما في السيرفر
                  _buildDataRow("موعد الحلقة :", _formatSessions(_data!["group"]?["groupSessions"])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // يوزع الأيقونة والعنوان
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF07427C), size: 22),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF07427C))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // العنوان في اليمين
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          // القيمة في اليسار
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSessions(List? sessions) {
    if (sessions == null || sessions.isEmpty) return "--";
    final days = {1: "السبت", 2: "الأحد", 3: "الإثنين", 4: "الثلاثاء", 5: "الأربعاء", 6: "الخميس", 7: "الجمعة"};
    try {
      return sessions.map((s) => "${days[s['day']]} ${s['hour']}").join(" - ");
    } catch (e) {
      return "--";
    }
  }
}
// --- شاشة السؤال الأسبوعي ---
class WeeklyQuestionsScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  const WeeklyQuestionsScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<WeeklyQuestionsScreen> createState() => _WeeklyQuestionsScreenState();
}

class _WeeklyQuestionsScreenState extends State<WeeklyQuestionsScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final String url = "https://nour-al-eman.runasp.net/api/Student/GetAllExamBsedOnType?StId=${widget.studentId}&TypeId=1";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        setState(() => _questions = decoded["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGrade(int examId, String grade, String note) async {
    const String postUrl = "https://nour-al-eman.runasp.net/api/StudentExams/AddStudentExam";
    try {
      final response = await http.post(
        Uri.parse(postUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "stId": widget.studentId,
          "examId": examId,
          "grade": int.tryParse(grade) ?? 0,
          "note": note,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم حفظ التقييم بنجاح"), backgroundColor: Colors.green));
          _fetch();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ خطأ في الإرسال"), backgroundColor: Colors.red));
    }
  }

  void _showGradingDialog(dynamic item, bool isGraded) {
    final TextEditingController noteController = TextEditingController(text: isGraded ? (item["note_teacher"] ?? "") : "");
    final TextEditingController gradeController = TextEditingController(text: item["grade"]?.toString() ?? "");
    final exam = item["exam"] ?? {};
    final int examId = exam["id"] ?? 0;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isGraded ? "التقييم" : "اضافة تقييم",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF07427C))),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.close, size: 16, color: Colors.black))
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("التعليق", style: TextStyle(fontSize: 16, color: Color(0xFF07427C), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: "اكتب هنا ...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: isGraded ? "نقاط الطالب" : "ادخل نقاط الطالب هنا",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red, fontSize: 16))],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: gradeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: "ادخل نقاط الطالب هنا",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD17820),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        _submitGrade(examId, gradeController.text, noteController.text);
                        Navigator.pop(context);
                      },
                      child: Text(isGraded ? "إغلاق" : "إضافة",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: const Text("الأسئلة الأسبوعية", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)))
            : _questions.isEmpty
            ? const Center(child: Text("لا يوجد بيانات بعد", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
            : Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Center(child: Text("اسم السؤال", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))),
                  Expanded(flex: 3, child: Center(child: Text("وصف السؤال", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))),
                  Expanded(flex: 2, child: Center(child: Text("إجابة الطالب", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))),
                  Expanded(flex: 2, child: Center(child: Text("تقييم الإجابة", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final item = _questions[index];
                  final exam = item["exam"] ?? {};
                  final bool isGraded = item["grade"] != null;
                  final String studentAnswer = item["note"]?.toString() ?? "--";
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isGraded ? const Color(0xFF2E7D32) : const Color(0xFFC62828), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Center(child: Text(exam["name"] ?? "--", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                        Expanded(flex: 3, child: Center(child: Text(exam["description"] ?? "--", style: const TextStyle(fontSize: 12), textAlign: TextAlign.center))),
                        Expanded(flex: 2, child: Center(child: Text(studentAnswer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)))),
                        Expanded(flex: 2, child: Center(child: InkWell(
                          onTap: () => _showGradingDialog(item, isGraded),
                          child: Text(isGraded ? "رؤية التقييم" : "تقييم الإجابة", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF07427C), decoration: TextDecoration.underline)),
                        ))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- شاشة الأبحاث ---
class StudentExamsScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  const StudentExamsScreen({super.key, required this.studentId, required this.studentName});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen> {
  bool _isLoading = true;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final String url = "https://nour-al-eman.runasp.net/api/Student/GetAllExamBsedOnType?StId=${widget.studentId}&TypeId=2";
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        setState(() => _tasks = decoded["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitGrade(int examId, String grade, String note) async {
    const String postUrl = "https://nour-al-eman.runasp.net/api/StudentExams/AddStudentExam";
    try {
      await http.post(
        Uri.parse(postUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "stId": widget.studentId,
          "examId": examId,
          "grade": int.tryParse(grade) ?? 0,
          "note": note,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ تم التقييم بنجاح"), backgroundColor: Colors.green));
        _fetch();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ خطأ في الإرسال")));
    }
  }

  void _showGradingDialog(dynamic item, bool isGraded) {
    final TextEditingController noteController = TextEditingController(text: item["note"] ?? "");
    final TextEditingController gradeController = TextEditingController(text: item["grade"]?.toString() ?? "");
    int examId = 0;
    if (item["examId"] != null) {
      examId = item["examId"];
    } else if (item["exam"] != null && item["exam"]["id"] != null) {
      examId = item["exam"]["id"];
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isGraded ? "تعديل تقييم البحث" : "تقييم البحث", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF07427C))),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.close, size: 16, color: Colors.black))
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("الملاحظة", style: TextStyle(fontSize: 14, color: Color(0xFF07427C), fontWeight: FontWeight.w500)),
                  TextField(controller: noteController, maxLines: 3, decoration: InputDecoration(hintText: "اكتب ملاحظتك هنا", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 15),
                  const Text("الدرجة", style: TextStyle(fontSize: 14, color: Color(0xFF07427C), fontWeight: FontWeight.w500)),
                  TextField(controller: gradeController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: "ادخل الدرجة", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD17820), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        _submitGrade(examId, gradeController.text, noteController.text);
                        Navigator.pop(context);
                      },
                      child: const Text("حفظ التقييم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload(String? relativeUrl, String fileName) async {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الرابط غير متاح")));
      return;
    }
    try {
      String cleanPath = relativeUrl.replaceAll(r'\', '/').trim();
      if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
      final String fullUrl = "https://nour-al-eman.runasp.net$cleanPath";
      final String savePath = "/storage/emulated/0/Download/$fileName";
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري بدء التحميل...")));
      await Dio().download(fullUrl, savePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ تم التحميل: $fileName"),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: "فتح", textColor: Colors.white, onPressed: () => OpenFilex.open(savePath)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ فشل التحميل")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text("أبحاث: ${widget.studentName}", style: const TextStyle(color: Colors.black, fontSize: 15)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
            ? const Center(child: Text("لا توجد أبحاث لهذا الطالب"))
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final item = _tasks[index];
            final exam = item["exam"] ?? {};
            final bool isGraded = item["grade"] != null;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: isGraded ? Colors.green : Colors.red, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _showGradingDialog(item, isGraded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFF07427C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(isGraded ? "رؤية التقييم" : "تقييم البحث",
                          style: const TextStyle(color: Color(0xFF07427C), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.download_for_offline, color: Color(0xFFD17820), size: 28),
                    onPressed: () => _startDownload(exam["url"], "${exam["name"] ?? "research"}.pdf"),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(exam["name"] ?? "بدون اسم", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(isGraded ? "تم التقييم" : "بانتظار التقييم", style: TextStyle(fontSize: 10, color: isGraded ? Colors.green : Colors.red)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}