import 'package:flutter/material.dart';

// تعريف الألوان لتكون موحدة مع مشروعك
final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);

class StudentHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text("لوحة تحكم الطالب", style: TextStyle(color: darkBlue)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildStudentSidebar(context),
        body: Center(child: Text("مرحباً بك في حساب الطالب")),
      ),
    );
  }

  Widget _buildStudentSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildSidebarHeader(),
          _buildSidebarItem(Icons.person_outline, "البيانات الشخصية", isSelected: true),
          _buildSidebarItem(Icons.fact_check_outlined, "حضور و غياب للمستوى الحالي"),
          _buildSidebarItem(Icons.menu_book_outlined, "مقررات المستوى"),
          _buildSidebarItem(Icons.assignment_outlined, "أعمال الطالب"),
          _buildSidebarItem(Icons.quiz_outlined, "الاختبارات"),
          Spacer(),
          Divider(),
          _buildSidebarItem(Icons.logout, "تسجيل الخروج", color: Colors.red, onTap: () => Navigator.pop(context)),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: Image.asset(
          'assets/full_logo.png',
          height: 100,
          errorBuilder: (c, e, s) => Icon(Icons.school, size: 80, color: primaryOrange),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false, Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryOrange : (color ?? darkBlue)),
      title: Text(title, style: TextStyle(color: isSelected ? primaryOrange : (color ?? darkBlue), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
      onTap: onTap,
    );
  }
}