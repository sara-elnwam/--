import 'package:flutter/material.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2); // اللون الأزرق من الصورة

class TeacherHomeScreen extends StatefulWidget {
  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  // متغير لتحديد العنصر المختار حالياً
  String _currentTitle = "البيانات الشخصية";

  void _onItemTapped(String title) {
    setState(() {
      _currentTitle = title;
    });
    Navigator.pop(context); // إغلاق السايدبار عند الضغط
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
          scrolledUnderElevation: 0,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildTeacherSidebar(context),
        body: Center(
            child: Text(
                "عرض محتوى: $_currentTitle",
                style: TextStyle(fontSize: 18, color: Colors.grey.shade400)
            )
        ),
      ),
    );
  }

  Widget _buildTeacherSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // لوجو الشركة - مرفوع للأعلى وبدون خط سفلي
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 10),
            child: Center(
              child: Image.asset(
                'assets/full_logo.png',
                height: 80,
                errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange),
              ),
            ),
          ),

          // العناصر الأساسية
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

          Divider(height: 1),

          // رفع تسجيل الخروج بمسافة 90 عن الأسفل
          Container(
            height: 80, // ارتفاع العنصر نفسه
            margin: EdgeInsets.only(bottom: 90), // الرفع عن الأسفل بمقدار 90
            child: Center(
              child: _buildSidebarItem(
                  Icons.logout,
                  "تسجيل الخروج",
                  color: Colors.red,
                  isLogout: true
              ),
            ),
          ),
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
          // إطار أبيض خفيف للمختار كالصورة المرفقة
          border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : (color ?? darkBlue),
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : (color ?? darkBlue),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          onTap: () {
            if (isLogout) {
              // هنا تضع بوب أب تسجيل الخروج
            } else {
              _onItemTapped(title);
            }
          },
        ),
      ),
    );
  }
}