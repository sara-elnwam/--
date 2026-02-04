import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_parent_details_screen.dart';

class AllEmployeesScreen extends StatefulWidget {
  @override
  _AllEmployeesScreenState createState() => _AllEmployeesScreenState();
}

class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
  List<dynamic> _allEmployees = [];
  List<dynamic> _filteredEmployees = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final Color darkBlue = const Color(0xFF2E3542);
  final Color kActiveBlue = const Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _fetchAllEmployees();
  }


  Future<void> _fetchAllEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetWithType?type=2'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allEmployees = data;
          _filteredEmployees = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword(int empId, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final url = Uri.parse('https://nour-al-eman.runasp.net/api/Student/ResetPassword');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "id": empId,
          "password": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("تم تغيير كلمة المرور بنجاح", Colors.green);
      } else {
        _showSnackBar("فشل تحديث كلمة المرور", Colors.red);
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء التحديث", Colors.red);
    }
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      final response = await http.post(
        Uri.parse('https://nour-al-eman.runasp.net/api/Account/DeActivate?id=$id&type=2'),
      );
      if (response.statusCode == 200) {
        _showSnackBar("تم حذف الموظف بنجاح", Colors.green);
        _fetchAllEmployees();
      }
    } catch (e) {
      _showSnackBar("خطأ في الاتصال", Colors.red);
    }
  }

  void _showResetPasswordDialog(int empId, String empName) {
    final TextEditingController _passController = TextEditingController();
    final TextEditingController _confirmPassController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("إعادة تعيين كلمة السر",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Almarai')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("من فضلك، قم بإدخال كلمة المرور الجديدة للموظف: $empName",
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontFamily: 'Almarai')),
                  const SizedBox(height: 20),
                  _buildPopupTextField("كلمة المرور", _passController),
                  const SizedBox(height: 15),
                  _buildPopupTextField("إعادة إدخال كلمة المرور", _confirmPassController),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: Colors.red, fontFamily: 'Almarai')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3542),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _isSubmitting ? null : () async {
                  if (_passController.text.length < 6) {
                    _showSnackBar("كلمة المرور قصيرة جداً", Colors.orange);
                    return;
                  }
                  if (_passController.text != _confirmPassController.text) {
                    _showSnackBar("كلمة المرور غير متطابقة", Colors.orange);
                    return;
                  }

                  setDialogState(() => _isSubmitting = true);
                  await _updatePassword(empId, _passController.text);
                  if (mounted) Navigator.pop(context);
                },
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("تغيير", style: TextStyle(color: Colors.white, fontFamily: 'Almarai')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(int empId) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: const Text("هل أنت متأكد من حذف هذا الموظف؟", textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("تراجع")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(context);
                _deleteEmployee(empId);
              },
              child: const Text("تأكيد الحذف", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
          elevation: 0.5,
          title: const Text("الموظفون", style: TextStyle(color: Color(0xFF2E3542), fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kActiveBlue))
            : Column(
          children: [
            _buildTableHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredEmployees.length,
                itemBuilder: (context, index) {
                  final emp = _filteredEmployees[index];
                  return _buildEmployeeRow(emp, index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        children: [
          _cellText("#", 1, isHeader: true),
          _cellText("الإسم", 4, isHeader: true),
          _cellText("الوظيفة", 2, isHeader: true),
          _cellText("البيانات", 2, isHeader: true),
          _cellText("كلمة المرور", 2, isHeader: true),
          _cellText("حذف", 1, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(dynamic emp, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          _cellText(index.toString(), 1),
          _cellText(emp['name'] ?? "---", 4, isBold: true),
          _cellText(emp['employeeType']?['name'] ?? "---", 2),
          _cellIcon(Icons.person, Colors.blue[900]!, 2, () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeParentDetailsScreen(
                  empId: emp['id'],
                  empName: emp['name'] ?? "بيانات الموظف",
                ),
              ),
            );
            _fetchAllEmployees();
          }),
          _cellIcon(Icons.lock, Colors.blue, 2, () => _showResetPasswordDialog(emp['id'], emp['name'])),
          _cellIcon(Icons.delete, Colors.redAccent, 1, () => _showDeleteConfirmDialog(emp['id'])),
        ],
      ),
    );
  }

  Widget _cellText(String text, int flex, {bool isHeader = false, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(
          color: isHeader ? Colors.grey[600] : darkBlue,
          fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 13,
          fontFamily: 'Almarai')),
    );
  }

  Widget _cellIcon(IconData icon, Color color, int flex, VoidCallback onTap) {
    return Expanded(flex: flex, child: InkWell(onTap: onTap, child: Icon(icon, color: color, size: 20)));
  }

  Widget _buildPopupTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, fontFamily: 'Almarai'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Almarai')), backgroundColor: color));
  }
}