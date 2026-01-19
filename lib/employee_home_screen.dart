import 'package:flutter/material.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);

class EmployeeHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text("لوحة تحكم الموظف", style: TextStyle(color: darkBlue)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildEmployeeSidebar(context),
        body: Center(child: Text("مرحباً بك في الإدارة")),
      ),
    );
  }

  Widget _buildEmployeeSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSidebarHeader(),
            _buildSidebarItem(Icons.home_outlined, "الصفحة الرئيسية"),
            _buildSidebarItem(Icons.person_outline, "البيانات الشخصية", isSelected: true),
            _buildSidebarItem(Icons.badge_outlined, "الحضور و الإنصراف"),
            _buildSidebarItem(Icons.school_outlined, "الطلاب"),
            _buildSidebarItem(Icons.record_voice_over_outlined, "المعلمون"),
            _buildSidebarItem(Icons.people_outline, "الموظفون"),
            _buildSidebarItem(Icons.layers_outlined, "المستويات و المجموعات"),
            _buildSidebarItem(Icons.account_tree_outlined, "الفروع"),
            _buildSidebarItem(Icons.verified_outlined, "الدورات"),
            _buildSidebarItem(Icons.hourglass_empty, "قائمة الإنتظار"),
            _buildSidebarItem(Icons.manage_accounts_outlined, "إدارة الموظفين"),
            Divider(),
            _buildSidebarItem(Icons.logout, "تسجيل الخروج", color: Colors.red),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return DrawerHeader(
      child: Center(child: Image.asset('assets/full_logo.png', height: 100, errorBuilder: (c, e, s) => Icon(Icons.school, size: 80, color: primaryOrange))),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryOrange : (color ?? darkBlue)),
      title: Text(title, style: TextStyle(color: isSelected ? primaryOrange : (color ?? darkBlue), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
    );
  }
}