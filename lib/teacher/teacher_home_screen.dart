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
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('user_id');

      if (id == null || id.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetById?id=$id'),
      );

      if (response.statusCode == 200) {
        final teacherModel = TeacherModel.fromJson(jsonDecode(response.body));
        setState(() {
          teacherData = teacherModel.data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
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
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildTeacherSidebar(context),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kActiveBlue))
            : RefreshIndicator(
          onRefresh: _fetchTeacherProfile,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTitle == "البيانات الشخصية") {
      // تعديل بسيط هنا لعرض التاريخ (سنة-شهر-يوم) فقط بدون الأصفار
      String rawDate = teacherData?.joinDate?.toString() ?? "---";
      String formattedDate = (rawDate != "---" && rawDate.length >= 10)
          ? rawDate.substring(0, 10)
          : rawDate;

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard("بيانات المعلم", Icons.badge_outlined, [
            _infoRow("اسم المعلم :", teacherData?.name ?? "---"),
            _infoRow("كود المعلم :", teacherData?.id?.toString() ?? "---"),
            _infoRow("المكتب التابع له :", teacherData?.loc?.name ?? "---"),
            _infoRow("موعد الالتحاق بالمدرسة :", formattedDate),
            _infoRow("المؤهل الدراسي :", teacherData?.educationDegree ?? "---"),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard("الدورات التدريبية الحاصل عليها", Icons.school_outlined, [
            if (teacherData?.courses == null || teacherData!.courses!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("لا توجد دورات تدريبية",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Almarai')),
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
    return Center(child: Text("قسم $_currentTitle", style: TextStyle(fontFamily: 'Almarai', color: darkBlue)));
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
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
                Text(title, style: TextStyle(color: kActiveBlue, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Almarai')),
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
          Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 14, fontFamily: 'Almarai')),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value,
              style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Almarai'),
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
              child: Image.asset('assets/full_logo.png', height: 80,
                  errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.only(bottom: 100.0),
            child: _buildSidebarItem(Icons.logout, "تسجيل الخروج", color: Colors.redAccent, isLogout: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {Color? color, bool isLogout = false}) {
    bool isSelected = _currentTitle == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kActiveBlue : (color ?? darkBlue)),
      title: Text(title, style: TextStyle(
          color: isSelected ? kActiveBlue : (color ?? darkBlue),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Almarai')),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog();
        } else {
          setState(() => _currentTitle = title);
          Navigator.pop(context);
        }
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
          content: Text("هل أنت متأكد؟", style: TextStyle(fontFamily: 'Almarai')),
          actions: [
            TextButton(child: Text("إلغاء"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
              },
              child: Text("خروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}