import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeAttendanceTab extends StatefulWidget {
  final int empId;

  const EmployeeAttendanceTab({super.key, required this.empId});

  @override
  _EmployeeAttendanceTabState createState() => _EmployeeAttendanceTabState();
}

class _EmployeeAttendanceTabState extends State<EmployeeAttendanceTab> {
  List<dynamic> _attendanceList = [];
  bool _isLoading = true;
  int? _expandedIndex;

  // الألوان المستخدمة في التصميم
  static const Color kPrimaryBlue = Color(0xFF1976D2);
  static const Color kHeaderGrey = Color(0xFFF9FAFB);
  static const Color kSuccessGreen = Color(0xFF2E7D32);
  static const Color kDangerRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Locations/GetAll-employee-attendance-ByEmpId?EmpId=${widget.empId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // التحقق من وجود بيانات في الـ data field
        setState(() {
          _attendanceList = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _mapNoteToText(int? noteId) {
    switch (noteId) {
      case 1: return "ممتاز";
      case 2: return "جيد جداً";
      case 3: return "جيد";
      case 5: return "ضعيف";
      default: return "غير محدد";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));
    }

    if (_attendanceList.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد بيانات!",
          style: TextStyle(
            color: kDangerRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Almarai',
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // الهيدر - مطابق للويب
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: const BoxDecoration(
              color: kHeaderGrey,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                _buildHeaderCell("موعد الحلقة", 2),
                _buildHeaderCell("الحضور", 1),
                _buildHeaderCell("حفظ قديم", 2),
                _buildHeaderCell("حفظ جديد", 2),
                _buildHeaderCell("تعليق", 2),
              ],
            ),
          ),

          Expanded(
            child: ListView.separated(
              itemCount: _attendanceList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final item = _attendanceList[index];
                bool isExpanded = _expandedIndex == index;

                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
                        child: Row(
                          children: [
                            // 1. التاريخ
                            Expanded(flex: 2, child: Text(item['createDate']?.split('T')[0] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),

                            // 2. حالة الحضور
                            Expanded(
                              flex: 1,
                              child: Text(
                                item['isPresent'] == true ? "حضور" : "غياب",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: item['isPresent'] == true ? kSuccessGreen : kDangerRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            // 3. الملاحظات (Mapping)
                            Expanded(flex: 2, child: Text(_mapNoteToText(item['oldAttendanceNote']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text(_mapNoteToText(item['newAttendanceNote']), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),

                            // 4. زر التفاصيل
                            Expanded(
                              flex: 2,
                              child: Text(
                                isExpanded ? "إخفاء" : "عرض التعليق",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isExpanded ? kDangerRed : kPrimaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // جزء التعليق المخفي
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.blue.withOpacity(0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "التعليق: ${item['note'] ?? 'لا يوجد تعليق'}",
                                style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Almarai'),
                              ),
                            ),
                            Text(
                              "النقاط: ${item['points'] ?? 0}",
                              style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Almarai'),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87, fontFamily: 'Almarai'),
      ),
    );
  }
}