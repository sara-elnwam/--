import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Student {
  final int id;
  final String name;
  Student({required this.id, required this.name});
}

class StudentAttendanceScreen extends StatefulWidget {
  final int groupId;
  final List<Student> students;

  const StudentAttendanceScreen({
    super.key,
    required this.groupId,
    required this.students,
  });

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isLoading = false;
  List<dynamic> _attendanceList = [];
  final List<String> _ratingOptions = ["ممتاز", "جيد جدا", "جيد", "مقبول", "ضعيف"];

  @override
  void initState() {
    super.initState();
    _attendanceList = widget.students.map((s) => {
      "stId": s.id,
      "name": s.name,
      "status": false,
      "oldSave": null,
      "newSave": null,
      "note": "",
    }).toList();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    String urlString = "https://nour-al-eman.runasp.net/api/Group/GetGroupAttendace?GroupId=${widget.groupId}";
    for (var student in widget.students) {
      urlString += "&ids=${student.id}";
    }

    try {
      final response = await http.get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List fetchedData = decoded["data"] ?? [];

        if (fetchedData.isNotEmpty) {
          setState(() {
            _attendanceList = fetchedData.map((item) => {
              "stId": item["id"],
              "name": item["name"] ?? "طالب",
              "status": false,
              "oldSave": null,
              "newSave": null,
              "note": "",
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(

        ),
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)))
            : Stack( // استخدام Stack لتمكين رفع الزر فوق القائمة
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 160), // مساحة إضافية للسماح بالاسكرول خلف الزر
                    itemCount: _attendanceList.length,
                    itemBuilder: (context, index) => _buildRow(index),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 90, // رفع الزر بمقدار 90 كما طلبت
              left: 0,
              right: 0,
              child: Center(child: _buildSaveButton()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07427C),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Center(child: Text("اسم الطالب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
          Expanded(flex: 1, child: Center(child: Text("حضور", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
          Expanded(flex: 2, child: Center(child: Text("حفظ قديم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
          Expanded(flex: 2, child: Center(child: Text("حفظ جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
          Expanded(flex: 2, child: Center(child: Text("تعليق المعلم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(flex: 3, child: Padding(padding: const EdgeInsets.all(8.0), child: Text(_attendanceList[index]["name"] ?? ""))),
            const VerticalDivider(width: 1),
            Expanded(flex: 1, child: Checkbox(
                value: _attendanceList[index]["status"],
                activeColor: const Color(0xFF07427C),
                onChanged: (v) => setState(() => _attendanceList[index]["status"] = v)
            )),
            const VerticalDivider(width: 1),
            _buildDropdown(index, "oldSave"),
            const VerticalDivider(width: 1),
            _buildDropdown(index, "newSave"),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 2, // زيادة المساحة لتناسب كلمة "تعليق"
              child: IconButton(
                icon: Icon(
                    Icons.comment_bank_outlined,
                    color: _attendanceList[index]["note"].isEmpty ? Colors.grey : const Color(0xFF07427C)
                ),
                onPressed: () => _showNoteDialog(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(int index, String key) {
    return Expanded(
      flex: 2,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Center(child: Text("اختر", style: TextStyle(fontSize: 10))),
          value: _attendanceList[index][key],
          items: _ratingOptions.map((v) => DropdownMenuItem(value: v, child: Center(child: Text(v, style: const TextStyle(fontSize: 11))))).toList(),
          onChanged: (val) => setState(() => _attendanceList[index][key] = val),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 200,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200, // لون رمادي فاتح
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
        ),
        onPressed: _attendanceList.isEmpty ? null : _saveData,
        child: const Text(
            "حفظ التعديلات",
            style: TextStyle(
                color: Color(0xFF81D4FA), // لون سماوي فاتح
                fontWeight: FontWeight.bold,
                fontSize: 16
            )
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    // منطق الحفظ هنا
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري حفظ البيانات...")));
  }

  void _showNoteDialog(int index) {
    TextEditingController c = TextEditingController(text: _attendanceList[index]["note"]);
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تعليق المعلم"),
          content: TextField(
              controller: c,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: "اكتب ملاحظاتك هنا...",
                  border: OutlineInputBorder()
              )
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07427C)),
                onPressed: () {
                  setState(() => _attendanceList[index]["note"] = c.text);
                  Navigator.pop(context);
                },
                child: const Text("حفظ التعليق", style: TextStyle(color: Colors.white))
            )
          ],
        ),
      ),
    );
  }
}