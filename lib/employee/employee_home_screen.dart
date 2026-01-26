import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/login_screen.dart';
import 'employee_model.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

class EmployeeHomeScreen extends StatefulWidget {
  @override
  _EmployeeHomeScreenState createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String _currentTitle = "الصفحة الرئيسية";
  bool _isLoading = true;
  EmployeeData? employeeData;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeProfile();
  }

  Future<void> _fetchEmployeeProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String id = prefs.getString('user_id') ?? "6";

      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetById?id=$id'),
      );

      if (response.statusCode == 200) {
        final employeeModel = EmployeeModel.fromJson(jsonDecode(response.body));
        setState(() {
          employeeData = employeeModel.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching employee data: $e");
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
          elevation: 0.5,
          scrolledUnderElevation: 0,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildEmployeeSidebar(context),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kActiveBlue))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTitle == "البيانات الشخصية") {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard("بيانات الموظف", Icons.person_pin_outlined, [
            _infoRow("اسم الموظف :", employeeData?.name ?? "---"),
            _infoRow("كود الموظف :", employeeData?.id?.toString() ?? "---"),
            _infoRow("المكتب التابع له :", employeeData?.loc?.name ?? "---"),
            _infoRow("موعد الالتحاق بالمدرسة :", employeeData?.joinDate?.toString().split(' ')[0] ?? "---"),
            _infoRow("المؤهل الدراسي :", employeeData?.educationDegree ?? "---"),
          ]),
        ],
      );
    }
    return Center(child: Text("محتوى قسم: $_currentTitle", style: TextStyle(color: Colors.grey)));
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

  Widget _buildEmployeeSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            child: Center(
                child: Image.asset('assets/full_logo.png',
                    height: 80,
                    errorBuilder: (c,e,s) => Icon(Icons.business, size: 50, color: kActiveBlue)
                )
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSidebarItem(Icons.home_outlined, "الصفحة الرئيسية"),
                  _buildSidebarItem(Icons.person_outline, "البيانات الشخصية"),
                  _buildSidebarItem(Icons.fact_check_outlined, "الحضور و الإنصراف"),
                  _buildSidebarItem(Icons.school_outlined, "الطلاب"),
                  _buildSidebarItem(Icons.person_search_outlined, "المعلمون"),
                  _buildSidebarItem(Icons.badge_outlined, "الموظفون"),
                  _buildSidebarItem(Icons.layers_outlined, "المستويات و المجموعات"),
                  _buildSidebarItem(Icons.location_on_outlined, "الفروع"),
                  _buildSidebarItem(Icons.menu_book_outlined, "الدورات"),
                  _buildSidebarItem(Icons.hourglass_empty, "قائمة الإنتظار"),
                  _buildSidebarItem(Icons.manage_accounts_outlined, "إدارة الموظفين"),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // تم رفع زر تسجيل الخروج وتعديل لونه
          _buildSidebarItem(
              Icons.logout,
              "تسجيل الخروج",
              color: Colors.redAccent,
              isLogout: true
          ),
          const SizedBox(height: 100), // الارتفاع المطلوب من الأسفل
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
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 0.5) : null,
        ),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          leading: Icon(icon, color: isSelected ? Colors.white : (color ?? darkBlue), size: 22),
          title: Text(title, style: TextStyle(
              color: isSelected ? Colors.white : (color ?? darkBlue),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13)),
          onTap: () => isLogout ? _showLogoutDialog() : _onItemTapped(title),
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
          surfaceTintColor: Colors.white, // منع تأثير الألوان في أندرويد 12+
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("تسجيل الخروج",
              style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
          content: const Text("هل أنت متأكد أنك تريد تسجيل الخروج؟"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // زر التأكيد بلون أحمر جذاب
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (c) => LoginScreen()),
                          (r) => false
                  );
                }
              },
              child: const Text("خروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}