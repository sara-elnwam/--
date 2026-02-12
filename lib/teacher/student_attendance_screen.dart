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

    // الرابط الذي ذكره الليدر لجلب حالة الحضور الحالية
    String urlString = "https://nour-al-eman.runasp.net/api/Group/GetGroupAttendace?GroupId=${widget.groupId}";

    try {
      final response = await http.get(Uri.parse(urlString));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List fetchedData = decoded["data"] ?? [];

        setState(() {
          // هنا نقوم برسم القائمة بناءً على البيانات الفعلية من السيرفر
          _attendanceList = fetchedData.map((item) => {
            "stId": item["id"], // تأكدي من مسمى الحقل في الـ JSON
            "name": item["name"] ?? "طالب",
            // إذا كان الطالب مسجل في جدول الحضور لهذا اليوم يكون status = true
            "status": item["isPresent"] ?? false,
            "oldSave": item["oldSave"],
            "newSave": item["newSave"],
            "note": item["note"] ?? "",
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // شيلنا الـ Scaffold والـ AppBar خالص عشان السهمين واللون يختفوا
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)))
          : Container(
        color: Colors.white, // بنوحد اللون عشان ميبقاش فيه لون غريب
        child: Stack(
          children: [
            Column(
              children: [
                // شلنا الـ Header القديم لو كان عامل زحمة
                Expanded(
                  child: ListView.builder(
                    // الـ padding هنا صفر عشان ميسيبش مسافة بينه وبين اللي فوقه
                    padding: const EdgeInsets.only(top: 0, bottom: 160),
                    itemCount: _attendanceList.length,
                    itemBuilder: (context, index) => _buildRow(index),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 100, // ظبطنا مكان الزرار تحت خالص
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
              child:// داخل الـ Row في ListView
              IconButton(
                icon: Icon(Icons.comment,
                    color: _attendanceList[index]["status"] ? Color(0xFF07427C) : Colors.grey // تغيير اللون لو مش حاضر
                ),
                onPressed: _attendanceList[index]["status"]
                    ? () => _showNoteDialog(index) // لو حاضر يفتح الدايلوج
                    : null, // لو مش حاضر الزرار ميعملش حاجة
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
        child:// مثال لدروب داون "الجديد"
        DropdownButton<String>(
          value: _attendanceList[index]["newSave"],
          hint: Text("اختر"),
          // الشرط السحري هنا
          onChanged: _attendanceList[index]["status"]
              ? (val) => setState(() => _attendanceList[index]["newSave"] = val)
              : null, // null هنا بتخلي الـ Dropdown معطل (Disabled)
          items: _ratingOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
            backgroundColor: const Color(0xFF07427C), // اللون الأزرق المعتمد
            elevation: 3,
            // التعديل هنا: خليت الـ borderRadius قليل جداً (5) عشان يبان مربع
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
        ),
        onPressed: _attendanceList.isEmpty ? null : _saveData,
        child: const Text(
            "حفظ التعديلات",
            style: TextStyle(
                color: Colors.white, // أبيض عشان يليق مع الأزرق الغامق
                fontWeight: FontWeight.bold,
                fontSize: 16
            )
        ),
      ),
    );
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);

    // تجهيز البيانات بالظبط زي ما السويجر طالب
    final List<Map<String, dynamic>> dataToSend = _attendanceList.map((s) {
      return {
        "id": 0, // كما هو موجود في السويجر
        "studentId": s["stId"], // معرف الطالب
        "groupId": widget.groupId, // معرف المجموعة
        "isPresent": s["status"], // هنا "صح" يعني true (حضور) و "بدون صح" يعني false (غياب)
        "points": int.tryParse(s["points"]?.toString() ?? "0") ?? 0, // تحويل النقاط لرقم
        "note": s["note"] ?? "", // التعليق
        "newAttendanceNote": _getRatingIndex(s["newSave"]), // تحويل التقييم (ممتاز، جيد..) لرقم
        "oldAttendanceNote": _getRatingIndex(s["oldSave"]),
        "createDate": DateTime.now().toIso8601String(), // تاريخ اليوم
        "createBy": "Teacher", // أو مسمى المعلم لو متاح
        "createFrom": "Mobile",
      };
    }).toList();

    try {
      final response = await http.post(
        Uri.parse("https://nour-al-eman.runasp.net/api/StudentAttendance/submit"),
        headers: {
          "accept": "*/*",
          "Content-Type": "application/json",
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ تم الحفظ بنجاح"), backgroundColor: Colors.green)
        );
      } else {
        print("Error: ${response.body}"); // عشان لو فيه خطأ نعرفه من الكونسول
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ خطأ من السيرفر: ${response.statusCode}"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ فشل الاتصال بالسيرفر"))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// دالة مساعدة لتحويل التقييم من نص لرقم عشان السيرفر يقبله
  int _getRatingIndex(String? rating) {
    if (rating == null) return 0;
    // الترتيب حسب الـ List اللي عندك: ["ممتاز", "جيد جدا", "جيد", "مقبول", "ضعيف"]
    List<String> ratings = ["ممتاز", "جيد جدا", "جيد", "مقبول", "ضعيف"];
    int index = ratings.indexOf(rating);
    return index != -1 ? (index + 1) : 0; // بيرجع 1 للممتاز، 2 لجيد جدا وهكذا
  }
  void _showNoteDialog(int index) {
    TextEditingController noteController = TextEditingController(text: _attendanceList[index]["note"]);
    // لو فيه متغير للنقاط في الـ list استخدميه، هنا هعمل له Controller
    TextEditingController pointsController = TextEditingController(text: _attendanceList[index]["points"]?.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white, // الخلفية بيضاء
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Center(
            child: Text(
              "إضافة تقييم وتعليق",
              style: TextStyle(color: Color(0xFF07427C), fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الكارت الأول: التعليق
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("التعليق", style: TextStyle(color: Color(0xFF07427C), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: "اكتب هنا...",
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none, // عشان شكل الكارت يبقى أنظف
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // الكارت الثاني: النقاط
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("النقاط", style: TextStyle(color: Color(0xFF07427C), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "ادخل نقاط الطالب هنا",
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07427C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _attendanceList[index]["note"] = noteController.text;
                  _attendanceList[index]["points"] = pointsController.text; // حفظ النقاط
                });
                Navigator.pop(context);
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}