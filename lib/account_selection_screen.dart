import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'student/student_home_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'employee/employee_home_screen.dart';

class AccountSelectionScreen extends StatelessWidget {
  final List<dynamic> accounts;

  const AccountSelectionScreen({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("اختر الحساب",
            style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFC66422),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "يرجى اختيار الحساب الذي تود الدخول إليه:",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Almarai',
                    color: Color(0xFF2E3542)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return _buildAccountCard(context, Map<String, dynamic>.from(account));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, Map<String, dynamic> account) {
    // تحديد نوع المستخدم للعرض فقط
    String userRole = "مستخدم";
    int type = int.tryParse(account['userType']?.toString() ?? "0") ?? 0;

    // المسميات بناءً على الـ userType لتسهيل التعرف على الحساب
    if (type == 1) userRole = "مدرس";
    else if (type == 2 || type == 3) userRole = "موظف";
    else userRole = "طالب";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC66422).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFFC66422)),
        ),
        title: Text(
          account['name'] ?? account['userName'] ?? "اسم غير معروف",
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: 'Almarai'),
        ),
        subtitle: Text("نوع الحساب: $userRole",
            style: const TextStyle(fontFamily: 'Almarai')),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _loginWithSelectedAccount(context, account),
      ),
    );
  }

  void _loginWithSelectedAccount(BuildContext context, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    // الحل الجذري: نأخذ الـ id الرقمي أولاً لأنه هو المطلوب لعمل الـ APIs القديمة
    // وإذا لم يوجد نأخذ الـ userId (GUID) كبديل
    String actualId = userData['id']?.toString() ?? userData['userId']?.toString() ?? "";

    await prefs.setString('user_token', userData['token']?.toString() ?? "");
    await prefs.setString('user_id', actualId);
    await prefs.setString('loginData', jsonEncode(userData));
    await prefs.setBool('is_logged_in', true);

    debugPrint("✅ Selection: Actual ID Saved ($actualId)");

    int userType = int.tryParse(userData['userType']?.toString() ?? "0") ?? 0;

    if (!context.mounted) return;

    Widget nextScreen;
    // توجيه المستخدم بناءً على نوع الحساب المختار
    if (userType == 1) {
      nextScreen = TeacherHomeScreen();
    } else if (userType == 2 || userType == 3) {
      nextScreen = EmployeeHomeScreen();
    } else {
      nextScreen = StudentHomeScreen(loginData: userData);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
          (route) => false,
    );
  }
}