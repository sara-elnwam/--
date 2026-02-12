import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LevelOneScreen extends StatefulWidget {
  final int levelId; // بياخد 1 أو 2 أو 5 حسب ما نضغط
  final String levelName;

  const LevelOneScreen({super.key, required this.levelId, required this.levelName});

  @override
  State<LevelOneScreen> createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends State<LevelOneScreen> {
  // تحويل اليوم لنص
  String _getDayName(dynamic day) {
    int dayInt = int.tryParse(day.toString()) ?? 0;
    const days = {
      1: "السبت", 2: "الأحد", 3: "الاثنين",
      4: "الثلاثاء", 5: "الأربعاء", 6: "الخميس", 7: "الجمعة"
    };
    return days[dayInt] ?? "";
  }

  // جلب البيانات بناءً على الـ levelId الممرر
  Future<List<dynamic>> fetchGroups() async {
    try {
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Group/Getall?levelid=${widget.levelId}'),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return decodedData['data'] ?? [];
      } else {
        return Future.error('خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      return Future.error('فشل في الاتصال: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlue = Color(0xFF2E3542);
    const Color orangeButton = Color(0xFFC66422);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(widget.levelName, // بيعرض "المستوى الثاني" مثلاً
              style: const TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Almarai')),
          iconTheme: const IconThemeData(color: darkBlue),
        ),

        // زر الإضافة الثابت تحت على جنب
        floatingActionButton: FloatingActionButton(
          heroTag: "fab_add_dynamic",
          onPressed: () {
            // هنا نفتح إضافة لمستوى معين
          },
          backgroundColor: orangeButton,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),

        body: FutureBuilder<List<dynamic>>(
          future: fetchGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: orangeButton));
            } else if (snapshot.hasError) {
              return Center(child: Text("حدث خطأ: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("لا يوجد مجموعات في هذا المستوى بعد, قم بإضافة مستوى!"));
            }

            final groups = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowHeight: 50,
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 120, // زيادة عشان مواعيد المستوى التاني كتير
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Expanded(child: Center(child: Text('المجموعة', style: TextStyle(fontWeight: FontWeight.bold))))),
                        DataColumn(label: Expanded(child: Center(child: Text('الشيخ', style: TextStyle(fontWeight: FontWeight.bold))))),
                        DataColumn(label: Expanded(child: Center(child: Text('المكان', style: TextStyle(fontWeight: FontWeight.bold))))),
                        DataColumn(label: Expanded(child: Center(child: Text('الطلاب', style: TextStyle(fontWeight: FontWeight.bold))))),
                        DataColumn(label: Expanded(child: Center(child: Text('المواعيد والوقت', style: TextStyle(fontWeight: FontWeight.bold))))),
                        DataColumn(label: Expanded(child: Center(child: Text('الاجراءات', style: TextStyle(fontWeight: FontWeight.bold))))),
                      ],
                      rows: groups.map((group) {
                        List sessions = group['groupSessions'] ?? [];

                        return DataRow(cells: [
                          DataCell(Center(child: Text(group['name'] ?? "", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))),
                          DataCell(Center(child: Text(group['emp']?['name'] ?? "---"))),
                          DataCell(Center(child: Text(group['loc']?['name'] ?? "---"))),
                          DataCell(Center(child: Text(group['studentCount']?.toString() ?? "0"))),
                          DataCell(
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: sessions.map((s) => Text(
                                  "${_getDayName(s['day'])} (${s['hour']})",
                                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                                )).toList(),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_note, color: Colors.blue, size: 24), onPressed: () {}),
                                  IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 24), onPressed: () {}),
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
            );
          },
        ),
      ),
    );
  }
}