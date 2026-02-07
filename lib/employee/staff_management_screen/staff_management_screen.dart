import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'role_permissions_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<dynamic> staffRoles = [];
  bool isLoading = true;
  bool isError = false;

  final Color primaryOrange = const Color(0xFFC66422);
  final Color successGreen = const Color(0xFF28A745);
  final Color dangerRed = const Color(0xFFDC3545);

  @override
  void initState() {
    super.initState();
    // تأمين جلب البيانات بعد استقرار واجهة المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchStaffRoles();
    });
  }

  Future<void> fetchStaffRoles() async {
    final url = Uri.parse('https://nour-al-eman.runasp.net/api/EmployeeType/GetAll');
    try {
      debugPrint("🚀 جاري جلب البيانات...");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint("📦 الـ Response وصل بنجاح: ${response.body}");
        if (mounted) {
          setState(() {
            staffRoles = responseData['data'] ?? [];
            isLoading = false;
            isError = false;
          });
        }
      } else {
        throw Exception("فشل الاتصال: ${response.statusCode}");
      }
    } catch (error) {
      debugPrint("❌ حدث خطأ أثناء الجلب: $error");
      if (mounted) {
        setState(() { isLoading = false; isError = true; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false, // العنوان يتبع لغة الجهاز تلقائياً
        title: const Text(
          "المسمى الوظيفي",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryOrange))
          : isError
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("حدث خطأ في جلب البيانات"),
          TextButton(onPressed: fetchStaffRoles, child: const Text("إعادة المحاولة")),
        ],
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildDataTable(),
            const SizedBox(height: 15),
            _buildAddButton(), // الزر مرفوع تحت الجدول مباشرة
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DataTable(
        columnSpacing: 10,
        headingRowHeight: 45,
        dataRowHeight: 50,
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: [
          DataColumn(label: Expanded(child: Text('الإسم', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          DataColumn(label: Expanded(child: Center(child: Text('الصلاحيات', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))))),
          DataColumn(label: Expanded(child: Text('الخيارات', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
        ],
        rows: staffRoles.map((item) {
          return DataRow(cells: [
            DataCell(Center(child: Text(item['name'] ?? '', style: const TextStyle(fontSize: 12)))),
            DataCell(
              Center(
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => RolePermissionsScreen(roleName: item['name']))),
                  child: const Text(
                    "عرض الصلاحيات",
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 11),
                  ),
                ),
              ),
            ),
            DataCell(
              Center(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit_note, color: Colors.black54, size: 22),
                  onPressed: () => _showRoleDialog(isEdit: true, id: item['id'], currentName: item['name']),
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: 100,
      height: 38,
      child: ElevatedButton(
        onPressed: () => _showRoleDialog(isEdit: false),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: const Text("إضافة", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showRoleDialog({required bool isEdit, int? id, String? currentName}) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "تعديل وظيفة" : "إضافة وظيفة",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              const SizedBox(height: 10),
              // تعديل السطر لجعل النجمة على اليسار دائماً
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text("المسمى الوظيفي", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Text("*", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: isEdit ? "" : "المسمى الوظيفي",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // الأزرار تبدأ من اتجاه اللغة (اليمين)
                children: [
                  // زر الحفظ/الإضافة (أخضر)
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: Text(isEdit ? "حفظ" : "إضافة", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  // زر الإلغاء (أحمر)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: const Text("إلغاء", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}