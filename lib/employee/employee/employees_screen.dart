import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'staff_model.dart';
import 'staff_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<StaffModel> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachersData();
  }

  Future<void> _fetchTeachersData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // سنستخدم الرابط العام GetAll للتأكد من سحب الـ 26 موظف كاملين
      // ثم سنقوم بفلترتهم داخل الكود لضمان عدم ضياع أي اسم
      final url = Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetAll');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // طباعة للفحص: ستجدي هنا الـ 26 كاملين إن شاء الله
      print("📥 اجمالي البيانات القادمة من السيرفر: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = json.decode(response.body);

        setState(() {
          // نحول كل البيانات ونفلتر المعلمين والمعلمات فقط يدوياً لضمان الدقة
          _teachers = decodedResponse
              .map((json) => StaffModel.fromJson(json))
              .where((emp) =>
          emp.employeeType?.name == "معلم/معلمة" ||
              emp.employeeType?.id == 1)
              .toList();

          _isLoading = false;
        });

        print("✅ عدد المعلمين بعد الفلترة الداخلية: ${_teachers.length}");
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ خطأ: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("بيانات المعلمين", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      // جسم الصفحة (بدون سكرول)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
          ? const Center(child: Text("لم يتم العثور على معلمين"))
          : Padding(
        padding: const EdgeInsets.all(5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: SingleChildScrollView( // سكرول رأسي فقط إذا زاد العدد عن الشاشة
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(25),  // #
                1: FlexColumnWidth(2.5),  // الإسم
                2: FlexColumnWidth(1.8),  // الوظيفة
                3: FixedColumnWidth(40),  // البيانات (العين)
                4: FixedColumnWidth(40),  // كلمة المرور (القفل)
                5: FixedColumnWidth(40),  // حذف (السلة)
              },
              children: [
                // الهيدر المطلوب
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _buildHeader("#"),
                    _buildHeader("الإسم"),
                    _buildHeader("الوظيفة"),
                    _buildHeader("البيانات"),
                    _buildHeader("كلمة المرور"),
                    _buildHeader("حذف"),
                  ],
                ),
                // الصفوف
                ..._teachers.asMap().entries.map((entry) {
                  int index = entry.key;
                  var teacher = entry.value;
                  return TableRow(
                    children: [
                      _buildCell("${index + 1}"),
                      _buildCell(teacher.name ?? "", isBold: true),
                      _buildCell(teacher.employeeType?.name ?? "معلم/ة"),
                      // أيقونة البيانات
                      _buildActionIcon(Icons.visibility_outlined, Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => StaffDetailsScreen(
                            staffId: teacher.id ?? 0,
                            staffName: teacher.name ?? "",
                          ),
                        ));
                      }),
                      // أيقونة كلمة المرور
                      _buildActionIcon(Icons.lock_outline, Colors.orange, () {}),
                      // أيقونة الحذف
                      _buildActionIcon(Icons.delete_outline, Colors.red, () {}),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
    );
  }

  Widget _buildCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontFamily: 'Almarai')),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}