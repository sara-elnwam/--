import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentWaitingListScreen extends StatefulWidget {
  const StudentWaitingListScreen({super.key});

  @override
  State<StudentWaitingListScreen> createState() => _StudentWaitingListScreenState();
}

class _StudentWaitingListScreenState extends State<StudentWaitingListScreen> {
  List<dynamic> allStudents = [];
  List<dynamic> filteredStudents = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Student/GetByStatus?status=false'),
      );

      if (response.statusCode == 200) {
        setState(() {
          allStudents = json.decode(response.body);
          filteredStudents = allStudents;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      filteredStudents = allStudents
          .where((student) =>
          student['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  Future<void> _handleAction(int id, bool isAccept) async {
    Navigator.pop(context); // إغلاق الديالوج
    setState(() => isLoading = true);

    try {
      // اختيار الرابط بناءً على العملية (قبول أم رفض)
      final String endpoint = isAccept ? 'SubmitUserLogin' : 'RefuseUserLogin';

      // بناء الرابط مع المعاملات المطلوبة (id و type)
      final url = Uri.parse(
          'https://nour-al-eman.runasp.net/api/Account/$endpoint?id=$id&type=0'
      );

      debugPrint(" إرسال طلب ${isAccept ? 'قبول' : 'رفض'} إلى: $url");

      // إرسال طلب POST حسب ما ظهر في الصور
      final response = await http.post(url);

      debugPrint(" الرد: ${response.body}");

      if (response.statusCode == 200) {
        // تحديث القائمة بعد نجاح العملية
        await _fetchStudents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAccept ? "تم قبول الطالب بنجاح" : "تم رفض الطلب بنجاح"),
              backgroundColor: isAccept ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        throw Exception("فشل الإجراء: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint(" خطأ: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ أثناء تنفيذ العملية")),
        );
      }
    }
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
            decoration: const InputDecoration(
              hintText: "ابحث عن اسم الطالب...",
              border: InputBorder.none,
              hintStyle: TextStyle(fontFamily: 'Almarai', fontSize: 14),
            ),
            style: const TextStyle(fontFamily: 'Almarai', fontSize: 14),
            onChanged: _filterStudents,
          )
              : const Text("طلبات تسجيل الطلاب",
              style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search, color: const Color(0xFFC66422)),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    _searchController.clear();
                    _filterStudents("");
                  }
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC66422)))
            : filteredStudents.isEmpty
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
          onRefresh: _fetchStudents,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 50,
                    columns: const [
                      DataColumn(label: Expanded(child: _HeaderCell("الإسم"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الهاتف"))),
                      DataColumn(label: Expanded(child: _HeaderCell("المكتب"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الحضور"))),
                      DataColumn(label: Expanded(child: _HeaderCell("الخيارات"))),
                    ],
                    rows: filteredStudents.map((student) {
                      return DataRow(cells: [
                        DataCell(Center(child: Text(student['name'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(student['phone'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(student['loc']?['name'] ?? "", style: _itemStyle()))),
                        DataCell(Center(child: Text(student['attendanceType'] ?? "", style: _itemStyle()))),
                        DataCell(
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _actionIcon(Icons.check, Colors.green, () => _showConfirmDialog(student['id'], true)),
                                const SizedBox(width: 8),
                                _actionIcon(Icons.close, Colors.red, () => _showConfirmDialog(student['id'], false)),
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
    );
  }

  TextStyle _itemStyle() => const TextStyle(fontFamily: 'Almarai', fontSize: 13, color: Colors.black87);

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showConfirmDialog(int id, bool isAccept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(25),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isAccept ? Icons.check_circle_outline : Icons.help_outline,
                size: 50, color: isAccept ? Colors.green : Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              isAccept ? "هل تريد قبول طلب التسجيل؟" : "هل أنت متأكد من رفض الطلب؟",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _dialogBtn("تأكيد", () => _handleAction(id, isAccept), const Color(0xFFC66422))),
                const SizedBox(width: 12),
                Expanded(child: _dialogBtn("إلغاء", () => Navigator.pop(context), Colors.grey.shade400)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _dialogBtn(String label, VoidCallback onTap, Color color) => ElevatedButton(
    style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    onPressed: onTap,
    child: Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Almarai')),
  );
}

class _HeaderCell extends StatelessWidget {
  final String label;

  // حذفنا حقل alignment تماماً لأنه كان يسبب مشكلة في الـ Hot Reload
  // ولأننا سنعتمد على التوسيط التلقائي
  const _HeaderCell(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Almarai',
          color: Color(0xFF2E3542),
          fontSize: 14,
        ),
      ),
    );
  }
}