import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
// اللون الأزرق الزاهي من الصورة
const Color kActiveBlue = Color(0xFF1976D2);

class EmployeeHomeScreen extends StatefulWidget {
  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String _currentTitle = "الصفحة الرئيسية";

  void _onItemTapped(String title) {
    setState(() {
      _currentTitle = title;
    });
    Navigator.pop(context);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("تسجيل الخروج", textAlign: TextAlign.right, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          content: Text("هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey.shade700)),
          actions: [
            TextButton(
              child: Text("إلغاء", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text("خروج", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false
                );
              },
            ),
          ],
        );
      },
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
          scrolledUnderElevation: 0,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildEmployeeSidebar(context),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Container(
            key: ValueKey<String>(_currentTitle),
            color: Colors.white,
            child: Center(
              child: Text(
                  _currentTitle,
                  style: TextStyle(fontSize: 24, color: Colors.grey.shade400, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // لوجو الشركة - مرفوع للأعلى وبدون خط سفلي
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 10),
            child: Center(
                child: Image.asset('assets/full_logo.png',
                    height: 80,
                    errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange)
                )
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(Icons.home_outlined, "الصفحة الرئيسية"),
                  _buildSidebarItem(Icons.person_outline, "البيانات الشخصية"),
                  _buildSidebarItem(Icons.badge_outlined, "الحضور و الإنصراف"),
                  _buildSidebarItem(Icons.school_outlined, "الطلاب"),
                  _buildSidebarItem(Icons.record_voice_over_outlined, "المعلمون"),
                  _buildSidebarItem(Icons.people_outline, "الموظفون"),
                  _buildSidebarItem(Icons.layers_outlined, "المستويات و المجموعات"),
                  _buildSidebarItem(Icons.account_tree_outlined, "الفروع"),
                  _buildSidebarItem(Icons.verified_outlined, "الدورات"),
                  _buildSidebarItem(Icons.hourglass_empty, "قائمة الإنتظار"),
                  _buildSidebarItem(Icons.manage_accounts_outlined, "إدارة الموظفين"),

                  // مسافة بسيطة قبل تسجيل الخروج (بارتفاع 80)
                  SizedBox(height: 10),
                  Divider(height: 1),

                  // تسجيل الخروج أصبح جزءاً من القائمة القابلة للتمرير ومرتفع للأعلى
                  SizedBox(
                    height: 120,
                    child: _buildSidebarItem(
                        Icons.logout,
                        "تسجيل الخروج",
                        color: Colors.red,
                        isLogout: true
                    ),
                  ),
                  SizedBox(height: 20), // مسافة أخيرة في نهاية السكرول
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          // اللون الأزرق من الصورة عند التحديد
          color: isSelected ? kActiveBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          // إطار أبيض خفيف حول العنصر المحدد مثل الصورة
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
                  fontSize: 14
              )
          ),
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
}