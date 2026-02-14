import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// استيراد صفحة تفاصيل الطالب اللي بعتيها
import 'student_details_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int groupId;
  final int levelId;
  final String groupName;
  final String teacherName; // استقبال اسم الشيخ الممرر

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.levelId,
    required this.groupName,
    required this.teacherName,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  final Color kPrimaryBlue = const Color(0xFF07427C);
  final Color kTextDark = const Color(0xFF2E3542);
  final Color orangeButton = const Color(0xFFC66422);

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // استخدام الإندبوينت الصحيحة بناءً على الـ GroupId والـ LevelId
      final url = Uri.parse(
          'https://nour-al-eman.runasp.net/api/Group/GetGroupDetails?GroupId=${widget.groupId}&LevelId=${widget.levelId}');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> studentsList = decodedData['data'] ?? [];

        if (mounted) {
          setState(() {
            _students = studentsList;
            _isLoading = false;
          });
        }
      } else {
        throw "Error: ${response.statusCode}";
      }
    } catch (e) {
      debugPrint("❌ Error fetching group details: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _students = [];
        });
      }
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
          title: Text("طلاب مجموعة: ${widget.groupName}",
              style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          iconTheme: IconThemeData(color: kTextDark),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
                heroTag: "edit_btn",
                onPressed: () {},
                backgroundColor: Colors.blue,
                child: const Icon(Icons.edit, color: Colors.white)),
            const SizedBox(height: 12),
            FloatingActionButton(
                heroTag: "add_student_btn",
                onPressed: () {},
                backgroundColor: orangeButton,
                child: const Icon(Icons.person_add,
                    color: Colors.white, size: 28)),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kPrimaryBlue))
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // كارت اسم الشيخ
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: kPrimaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: kPrimaryBlue.withOpacity(0.1))),
                child: Row(
                  children: [
                    Icon(Icons.person, color: kPrimaryBlue),
                    const SizedBox(width: 10),
                    Text("الشيخ: ",
                        style: TextStyle(
                            fontFamily: 'Almarai',
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue)),
                    Text(widget.teacherName,
                        style: TextStyle(
                            fontFamily: 'Almarai', color: kTextDark)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // جدول الطلاب
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: _students.isEmpty
                      ? const Center(child: Text("المجموعة فارغة"))
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(4),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                                color: Colors.grey[100]),
                            children: [
                              _buildHeaderCell("#"),
                              _buildHeaderCell("الاسم",
                                  align: TextAlign.right),
                              _buildHeaderCell("بيانات"),
                              _buildHeaderCell("سر"),
                              _buildHeaderCell("حذف"),
                            ],
                          ),
                          ..._students.asMap().entries.map((entry) {
                            int index = entry.key;
                            var student = entry.value;
                            return TableRow(
                              children: [
                                _buildDataCell("${index + 1}"),
                                _buildDataCell(
                                    student['name'] ?? "بدون اسم",
                                    align: TextAlign.right),

                                // زر البيانات: يفتح صفحة تفاصيل الطالب بالملي
                                _buildActionIcon(
                                    Icons.person_outline,
                                    Colors.blue, () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentDetailsScreen(
                                            studentId: student['id'],
                                            studentName:
                                            student['name'] ?? "",
                                          ),
                                    ),
                                  );
                                }),

                                // زر كلمة السر (يمكن برمجته لاحقاً)
                                _buildActionIcon(Icons.lock_open,
                                    Colors.orange, () {}),

                                // زر الحذف (يمكن برمجته لاحقاً)
                                _buildActionIcon(
                                    Icons.delete_outline,
                                    Colors.red, () {}),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.center}) =>
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text,
            textAlign: align,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Almarai')),
      );

  Widget _buildDataCell(String text, {TextAlign align = TextAlign.center}) =>
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text,
            textAlign: align,
            style: const TextStyle(fontSize: 13, fontFamily: 'Almarai')),
      );

  // تحديث دالة الأيقونة لتستقبل وظيفة الضغط (onTap)
  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
      );
}