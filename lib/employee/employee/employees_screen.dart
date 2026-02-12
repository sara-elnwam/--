import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'staff_model.dart';
import 'staff_details_screen.dart';

class EmployeesScreen extends StatefulWidget {
  @override
  _EmployeesScreenState createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<StaffModel> _allEmployees = [];
  List<StaffModel> _filteredEmployees = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final Color kPrimaryBlue = const Color(0xFF07427C);
  final Color kTextDark = const Color(0xFF2E3542);

  @override
  void initState() {
    super.initState();
    _fetchTeachersData();
  }

  Future<void> _fetchTeachersData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // الرابط المخصص للمعلمين
      final url = Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetWithType/?type=1');

      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> dataList = [];

        // التحقق مما إذا كانت البيانات بداخل 'data' أو هي القائمة مباشرة
        if (responseData is Map && responseData.containsKey('data')) {
          dataList = responseData['data'];
        } else if (responseData is List) {
          dataList = responseData;
        }

        List<StaffModel> loadedTeachers = [];
        for (var item in dataList) {
          loadedTeachers.add(StaffModel.fromJson(item));
        }

        setState(() {
          _allEmployees = loadedTeachers;
          _filteredEmployees = _allEmployees;
          _isLoading = false;
        });
      } else {
        print("خطأ من السيرفر: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("حدث خطأ: $e");
      setState(() => _isLoading = false);
    }
  }
  void _filterSearch(String query) {
    setState(() {
      _filteredEmployees = _allEmployees
          .where((emp) => emp.name!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        // ابحث عن السطر ده وغير قيمته من true لـ false
        centerTitle: false,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _filterSearch,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: "ابحث عن معلم...", border: InputBorder.none, hintStyle: TextStyle(fontFamily: 'Almarai', fontSize: 14)),
        )
            : Text("اسماء  المعلمين", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, color: kTextDark, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: kPrimaryBlue),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredEmployees = _allEmployees;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1), // رقم #
                  1: FlexColumnWidth(4), // الاسم
                  2: FlexColumnWidth(2), // بيانات
                  3: FlexColumnWidth(2), // السر
                  4: FlexColumnWidth(1.5), // حذف
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: [
                      _buildHeaderCell("#"),
                      _buildHeaderCell("الاسم", align: TextAlign.right),
                      _buildHeaderCell("بيانات"),
                      _buildHeaderCell("السر"),
                      _buildHeaderCell("حذف"),
                    ],
                  ),
                  ..._filteredEmployees.asMap().entries.map((entry) {
                    int index = entry.key;
                    var teacher = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
                      ),
                      children: [
                        _buildDataCell("${index + 1}"),
                        _buildDataCell(teacher.name ?? "---", align: TextAlign.right, isBold: true),
                        _buildActionCell(Icons.person_outline, Colors.blue[800]!, () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (c) => StaffDetailsScreen(staffId: teacher.id!, staffName: teacher.name!),
                          ));
                        }),
                        _buildActionCell(Icons.lock_open_rounded, Colors.blue[400]!, () {}),
                        _buildActionCell(Icons.delete_outline, Colors.red[400]!, () {}),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      child: Text(text, textAlign: align, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700], fontFamily: 'Almarai')),
    );
  }

  Widget _buildDataCell(String text, {TextAlign align = TextAlign.center, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      child: Text(text, textAlign: align, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, color: kTextDark, fontFamily: 'Almarai')),
    );
  }

  Widget _buildActionCell(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, color: color, size: 22), onPressed: onTap);
  }
}