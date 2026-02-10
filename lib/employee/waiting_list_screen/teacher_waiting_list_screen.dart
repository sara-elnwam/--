import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TeacherWaitingListScreen extends StatefulWidget {
  const TeacherWaitingListScreen({super.key});

  @override
  State<TeacherWaitingListScreen> createState() => _TeacherWaitingListScreenState();
}

class _TeacherWaitingListScreenState extends State<TeacherWaitingListScreen> {
  List<dynamic> allTeachers = [];
  List<dynamic> filteredTeachers = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  // جلب البيانات (GET)
  Future<void> _fetchTeachers() async {
    try {
      setState(() => isLoading = true);
      final url = 'https://nour-al-eman.runasp.net/api/Employee/GetByStatus?status=false&type=1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        setState(() {
          allTeachers = jsonData is List ? jsonData : [];
          filteredTeachers = allTeachers;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // دالة القبول أو الحذف (POST)
  Future<void> _handleAction(int id, bool isAccept) async {
    Navigator.pop(context); // إغلاق الديالوج
    setState(() => isLoading = true);

    try {
      // الـ Endpoint بناءً على الصور اللي بعتيها
      final String endpoint = isAccept ? 'SubmitUserLogin' : 'RefuseUserLogin';
      final url = Uri.parse('https://nour-al-eman.runasp.net/api/Account/$endpoint?id=$id&type=1');

      final response = await http.post(url);

      if (response.statusCode == 200) {
        await _fetchTeachers(); // تحديث القائمة
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAccept ? "تم قبول المعلم بنجاح" : "تم حذف الطلب بنجاح"),
              backgroundColor: isAccept ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterTeachers(String query) {
    setState(() {
      filteredTeachers = allTeachers
          .where((teacher) =>
      (teacher['name'] ?? "").toString().contains(query) ||
          (teacher['ssn'] ?? "").toString().contains(query))
          .toList();
    });
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
          title: isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "ابحث بالاسم أو الرقم القومي...", border: InputBorder.none),
            onChanged: _filterTeachers,
          )
              : const Text("طلبات تسجيل المعلمين", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search, color: const Color(0xFFC66422)),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    _searchController.clear();
                    _filterTeachers("");
                  }
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC66422)))
            : filteredTeachers.isEmpty
            ? Center(
          child: Text(
            "لا يوجد طلبات تسجيل جديدة!",
            style: TextStyle(
              fontFamily: 'Almarai',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchTeachers,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Expanded(child: _HeaderCell("الإسم"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الهاتف"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الرقم القومي"))),
                      DataColumn(label: Expanded(child: _HeaderCell("المكتب"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الخيارات"))),
                    ],
                    rows: filteredTeachers.map((teacher) {
                      return DataRow(cells: [
                        DataCell(Center(child: Text(teacher['name'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(teacher['phone'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(teacher['ssn'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(teacher['loc']?['name'] ?? "", style: _itemStyle()))),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _actionIcon(Icons.check, Colors.green, () => _showConfirmDialog(teacher['id'], true)),
                                const SizedBox(width: 8),
                                _actionIcon(Icons.close, Colors.red, () => _showConfirmDialog(teacher['id'], false)),
                              ],
                            ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ); // <-- تأكدي إن القوس ده موجود وبيقفل الـ Directionality
  }
  TextStyle _itemStyle() => const TextStyle(fontFamily: 'Almarai', fontSize: 13);

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showConfirmDialog(int id, bool isAccept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isAccept ? Icons.check_circle_outline : Icons.delete_outline,
                size: 50, color: isAccept ? Colors.green : Colors.red),
            const SizedBox(height: 15),
            Text(
              isAccept ? "هل تريد قبول المعلم؟" : "هل تريد حذف هذا الطلب؟",
              style: const TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(id, isAccept),
                    style: ElevatedButton.styleFrom(backgroundColor: isAccept ? Colors.green : Colors.red),
                    child: const Text("تأكيد", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("إلغاء"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Almarai', color: Color(0xFF2E3542))));
  }
}