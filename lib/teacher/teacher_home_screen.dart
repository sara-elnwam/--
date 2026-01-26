import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/login_screen.dart';
import 'teacher_model.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

class TeacherHomeScreen extends StatefulWidget {
  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  String _currentTitle = "البيانات الشخصية";
  bool _isLoading = true;
  TeacherData? teacherData;

  @override
  void initState() {
    super.initState();
    _fetchTeacherProfile();
  }

  Future<void> _fetchTeacherProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String id = prefs.getString('user_id') ?? "6";

      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetById?id=$id'),
      );

      if (response.statusCode == 200) {
        final teacherModel = TeacherModel.fromJson(jsonDecode(response.body));
        setState(() {
          teacherData = teacherModel.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(String title) {
    setState(() => _currentTitle = title);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildTeacherSidebar(context),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kActiveBlue))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTitle == "البيانات الشخصية" || _currentTitle == "الصفحة الرئيسية") {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard("بيانات المعلم", Icons.badge_outlined, [
            _infoRow("اسم المعلم :", teacherData?.name ?? "---"),
            _infoRow("كود المعلم :", teacherData?.id?.toString() ?? "---"),
            _infoRow("المكتب التابع له :", teacherData?.loc?.name ?? "---"),
            _infoRow("موعد الالتحاق بالمدرسة :", teacherData?.joinDate?.toString().split(' ')[0] ?? "---"),
            _infoRow("المؤهل الدراسي :", teacherData?.educationDegree ?? "---"),
          ]),

          const SizedBox(height: 16),

          _buildInfoCard("الدورات التدريبية الحاصل عليها", Icons.school_outlined, [
            if (teacherData?.courses == null || teacherData!.courses!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("لا توجد دورات تدريبية",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            else
              ...teacherData!.courses!.map((course) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _infoRow("اسم الدورة :", course.toString()),
              )).toList(),
          ]),
        ],
      );
    }
    return Center(child: Text("قسم $_currentTitle قيد التطوير"));
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: kActiveBlue, size: 22),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: kActiveBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
              style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 10),
            child: Center(
              child: Image.asset(
                  'assets/full_logo.png',
                  height: 80,
                  errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange)
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(Icons.home_outlined, "الصفحة الرئيسية"),
                  _buildSidebarItem(Icons.person_outline, "البيانات الشخصية"),
                  _buildSidebarItem(Icons.fact_check_outlined, "الحضور و الإنصراف"),
                  _buildSidebarItem(Icons.menu_book_outlined, "المنهج / المقرر"),
                  _buildSidebarItem(Icons.groups_outlined, "المجموعات"),
                  _buildSidebarItem(Icons.access_time, "مواعيد الدرس"),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // تم رفع زر تسجيل الخروج هنا
          _buildSidebarItem(
              Icons.logout,
              "تسجيل الخروج",
              color: Colors.redAccent,
              isLogout: true
          ),
          const SizedBox(height: 90), // المسافة المطلوبة من الأسفل
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {Color? color, bool isLogout = false}) {
    bool isSelected = _currentTitle == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? kActiveBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: Colors.white, width: 0.5) : null,
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          leading: Icon(icon, color: isSelected ? Colors.white : (color ?? darkBlue), size: 22),
          title: Text(title, style: TextStyle(
              color: isSelected ? Colors.white : (color ?? darkBlue),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14)),
          onTap: () {
            if (isLogout) {
              _showLogoutDialog();
            } else {
              _onItemTapped(title);
            }
          },
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white, // خلفية بيضاء
          surfaceTintColor: Colors.white, // لضمان بقاء اللون أبيض في الماتيريال 3
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("تسجيل الخروج", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج؟"),
          actions: [
            TextButton(
                child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.pop(context)
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // لون أحمر هادئ واحترافي
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
              },
              child: const Text("خروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}