import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final Color kPrimaryOrange = const Color(0xFFD36B2B);
  final Color kDarkBlue = const Color(0xFF2E3542);
  final Color kBgColor = const Color(0xFFF3F4F6);

  List<dynamic> currentData = [];
  bool isLoading = true;
  int _currentTabIndex = 0;

  // متغيرات الـ Popup
  bool isMandatory = false;
  String? selectedFileName;
  String? selectedLevel;

  final List<String> levelsList = ["المستوى الأول", "المستوى الثاني", "المستوى الثالث", "المستوى الرابع"];

  final List<Map<String, dynamic>> tabItems = [
    {'title': 'الاختبارات', 'id': 5},
    {'title': 'المناهج التعليمية', 'id': 3},
    {'title': 'الأبحاث', 'id': 2},
    {'title': 'السؤال الأسبوعي', 'id': 1},
    {'title': 'المقررات', 'id': 4},
  ];

  @override
  void initState() {
    super.initState();
    fetchData(tabItems[0]['id']);
  }

  Future<void> fetchData(int typeId) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("https://nour-al-eman.runasp.net/api/StudentCources/GetAll?type=$typeId"),
      );
      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          currentData = decodedData['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickFile(StateSetter setModalState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setModalState(() {
        selectedFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: tabItems.length,
        child: Scaffold(
          backgroundColor: kBgColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text("دورات الطلاب", style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Almarai')),
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: kPrimaryOrange,
              labelColor: kPrimaryOrange,
              unselectedLabelColor: Colors.grey,
              onTap: (index) {
                setState(() => _currentTabIndex = index);
                fetchData(tabItems[index]['id']);
              },
              labelStyle: const TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 13),
              tabs: tabItems.map((item) => Tab(text: item['title'])).toList(),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddEditModal(context, isEdit: false),
            backgroundColor: kPrimaryOrange,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
          body: Column(
            children: [
              _buildSectionTitle(),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 750,
                    child: Column(
                      children: [
                        _buildTableHeader(),
                        Expanded(
                          child: isLoading
                              ? Center(child: CircularProgressIndicator(color: kPrimaryOrange))
                              : _buildDataTable(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.table_chart_outlined, color: kPrimaryOrange, size: 20),
          const SizedBox(width: 8),
          Text("قائمة ${tabItems[_currentTabIndex]['title']}", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, color: kDarkBlue)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey.shade200, border: Border.all(color: Colors.grey.shade300), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("الاسم", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 4, child: Text("الوصف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text("المستوى", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 1, child: Center(child: Text("إجباري", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 1, child: Center(child: Text("تعديل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Expanded(flex: 1, child: Center(child: Text("حذف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (currentData.isEmpty) return const Center(child: Text("لا توجد بيانات حالياً"));
    return ListView.builder(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80),
      itemCount: currentData.length,
      itemBuilder: (context, index) {
        final item = currentData[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade300), right: BorderSide(color: Colors.grey.shade300), bottom: BorderSide(color: Colors.grey.shade300))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item['name'] ?? "-", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                Expanded(flex: 4, child: Text(item['description'] ?? "-", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                Expanded(flex: 2, child: Text(item['level'] != null ? item['level']['name'].toString() : "-", style: const TextStyle(fontSize: 11))),
                Expanded(flex: 1, child: Center(child: Icon((item['mandatory'] == true) ? Icons.check : Icons.close, color: Colors.red, size: 18))),
                Expanded(flex: 1, child: InkWell(onTap: () => _showAddEditModal(context, isEdit: true, data: item), child: Icon(Icons.edit_note, color: kPrimaryOrange, size: 22))),
                Expanded(flex: 1, child: InkWell(onTap: () => _showDeleteDialog(context), child: const Icon(Icons.delete, color: Colors.red, size: 20))),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEditModal(BuildContext context, {required bool isEdit, dynamic data}) {
    // تم إصلاح الخطأ هنا باستخدام القوسين
    isMandatory = isEdit ? (data['mandatory'] ?? false) : false;
    selectedLevel = isEdit ? (data['level'] != null ? data['level']['name'] : null) : null;
    selectedFileName = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                  _buildPopupField("الاسم*", isEdit ? data['name'] : "ادخل اسم المقرر"),
                  _buildPopupField("التفاصيل*", isEdit ? data['description'] : "ادخل تفاصيل المقرر"),

                  // دروب داون المستويات
                  _buildDropdownField(setModalState),
                  const SizedBox(height: 15),

                  // رفع الملفات
                  _buildFileUploadSection(setModalState),
                  const SizedBox(height: 15),

                  // زر إجباري
                  Row(
                    children: [
                      Checkbox(
                        value: isMandatory,
                        activeColor: kPrimaryOrange,
                        onChanged: (val) => setModalState(() => isMandatory = val!),
                      ),
                      const Text("إجباري", style: TextStyle(fontFamily: 'Almarai', fontSize: 13)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isEdit ? "حفظ" : "إضافة", style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Almarai')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("المستويات*", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(selectedLevel ?? "اختيار المستويات", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              items: levelsList.map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) => setModalState(() => selectedLevel = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadSection(StateSetter setModalState) {
    return Column(
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(selectedFileName ?? "No file chosen", style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis))),
              InkWell(
                onTap: () => _pickFile(setModalState),
                child: Container(
                  width: 90,
                  height: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey.shade200, border: Border(right: BorderSide(color: Colors.grey.shade300))),
                  child: const Center(child: Text("Choose File", style: TextStyle(fontSize: 11))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Align(alignment: Alignment.centerRight, child: Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 20)),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text("تأكيد الحذف!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Almarai')),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("تأكيد", style: TextStyle(color: Colors.white, fontFamily: 'Almarai')))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("إلغاء", style: TextStyle(color: Colors.white, fontFamily: 'Almarai')))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPopupField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: TextField(decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12, color: Colors.grey), border: InputBorder.none)),
          ),
        ],
      ),
    );
  }
}