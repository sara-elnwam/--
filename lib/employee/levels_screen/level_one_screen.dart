import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'group_details_screen.dart';


class LevelOneScreen extends StatefulWidget {
  final int levelId;
  final String levelName;

  const LevelOneScreen({super.key, required this.levelId, required this.levelName});

  @override
  State<LevelOneScreen> createState() => _LevelOneScreenState();
}

class _LevelOneScreenState extends State<LevelOneScreen> {
  final Color darkBlue = const Color(0xFF2E3542);
  final Color orangeButton = const Color(0xFFC66422);
  final Color kPrimaryBlue = const Color(0xFF07427C);

  late String displayedLevelName;
  List<dynamic> teachersList = [];
  List<dynamic> locationsList = [];

  int? selectedTeacherId;
  int? selectedLocationId;
  List<int> selectedDays = [];
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    displayedLevelName = widget.levelName;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final locRes = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Locations/Getall'));
      final techRes = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Employee/Getall'));
      if (mounted) {
        setState(() {
          locationsList = jsonDecode(locRes.body)['data'] ?? [];
          teachersList = jsonDecode(techRes.body)['data'] ?? [];
        });
      }
    } catch (e) { debugPrint("Data Load Error: $e"); }
  }

  String _getDayName(dynamic day) {
    int dayInt = int.tryParse(day.toString()) ?? 0;
    const days = {1: "السبت", 2: "الأحد", 3: "الاثنين", 4: "الثلاثاء", 5: "الأربعاء", 6: "الخميس", 7: "الجمعة"};
    return days[dayInt] ?? "";
  }

  Future<List<dynamic>> fetchGroups() async {
    final response = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Group/Getall?levelid=${widget.levelId}'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? [];
    }
    return [];
  }

  Future<void> _addGroupApi(String name) async {
    String formattedTime = selectedTime != null
        ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
        : "00:00";

    final response = await http.post(
      Uri.parse('https://nour-al-eman.runasp.net/api/Group/Save'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "levelId": widget.levelId,
        "empId": selectedTeacherId?.toString(), // تحويل لـ String كما في الصورة
        "LocId": selectedLocationId?.toString(), // تحويل لـ String كما في الصورة
        "Active": true, // إضافة الحقلين معاً لضمان القبول
        "Status": true,
        "days": selectedDays,
        "time": formattedTime,
      }),
    );

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          selectedDays = [];
          selectedTime = null;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إضافة المجموعة بنجاح"), backgroundColor: Colors.green),
        );
      }
    } else {
      debugPrint("خطأ من السيرفر: ${response.body}");
    }
  }
  Future<void> _updateLevelApi(String newName) async {
    final response = await http.put(
      Uri.parse('https://nour-al-eman.runasp.net/api/Level/Update'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": widget.levelId, "name": newName}),
    );
    if (response.statusCode == 200) { setState(() => displayedLevelName = newName); }
  }

  Future<void> _deleteGroupApi(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('https://nour-al-eman.runasp.net/api/Group/Delete?id=$id'),
      );
      if (response.statusCode == 200) {
        setState(() {}); // لتحديث الجدول بعد الحذف
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حذف المجموعة بنجاح"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _showAddGroupDialog() {
    TextEditingController nameCont = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.4),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ScaleTransition(
            scale: anim1,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Center(child: Text("إضافة مجموعة", style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold))),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("اسم المجموعة"),
                        TextField(controller: nameCont, decoration: _inputDecoration("الاسم")),
                        const SizedBox(height: 15),
                        _buildLabel("الشيخ"),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: _inputDecoration("اختر الشيخ"),
                          items: teachersList.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['name'] ?? ""))).toList(),
                          onChanged: (val) => selectedTeacherId = val,
                        ),
                        const SizedBox(height: 15),
                        _buildLabel("وقت الحصة"),
                        StatefulBuilder(builder: (context, setDialogState) {
                          return OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime == null ? "اختر الوقت" : selectedTime!.format(context)),
                            onPressed: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                                setState(() => selectedTime = picked);
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 15),
                        _buildLabel("المكتب"),
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: _inputDecoration("اختر المكتب"),
                          items: locationsList.map((l) => DropdownMenuItem<int>(value: l['id'], child: Text(l['name'] ?? ""))).toList(),
                          onChanged: (val) => selectedLocationId = val,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel("الأيام"),
                        StatefulBuilder(builder: (context, setSt) => Wrap(
                          spacing: 5,
                          children: List.generate(7, (i) {
                            final days = ["السبت", "الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"];
                            bool isSel = selectedDays.contains(i + 1);
                            return FilterChip(
                              label: Text(days[i], style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black)),
                              selected: isSel,
                              selectedColor: orangeButton,
                              onSelected: (v) => setSt(() => v ? selectedDays.add(i+1) : selectedDays.remove(i+1)),
                            );
                          }),
                        )),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
                  ElevatedButton(onPressed: () => _addGroupApi(nameCont.text), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryBlue), child: const Text("إضافة", style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditLevelDialog() {
    TextEditingController nameCont = TextEditingController(text: displayedLevelName);
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تعديل اسم المستوى"),
          content: TextField(controller: nameCont, decoration: _inputDecoration("اسم المستوى الجديد")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(onPressed: () { _updateLevelApi(nameCont.text); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("حفظ", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int groupId, String name) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد الحذف"),
          content: Text("هل أنت متأكد من حذف $name؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            ElevatedButton(
                onPressed: () {
                  _deleteGroupApi(groupId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("حذف", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint, filled: true, fillColor: Colors.white.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
  );

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(displayedLevelName, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
                heroTag: "edit",
                onPressed: _showEditLevelDialog,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.edit, color: Colors.white)
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
                heroTag: "add",
                onPressed: _showAddGroupDialog,
                backgroundColor: orangeButton,
                child: const Icon(Icons.add, color: Colors.white, size: 30)
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: fetchGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("لا توجد مجموعات"));

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 120,
                      headingRowColor: WidgetStateProperty.all(kPrimaryBlue.withOpacity(0.05)),
                      columns: const [
                        DataColumn(label: Text('المجموعة', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الشيخ', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('المكان', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الطلاب', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('المواعيد', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('إجراءات', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      // --- الجزء المعدل يبدأ من هنا ---
                      rows: snapshot.data!.map((group) {
                        // السيرفر يرسل المواعيد في حقل sessions حسب الصورة الأخيرة
                        List sessions = group['sessions'] ?? group['groupSessions'] ?? [];

                        return DataRow(cells: [
                          // 1. خلية اسم المجموعة (قابلة للضغط)
                          DataCell(
                            InkWell(
                              // داخل DataCell في LevelOneScreen
                              onTap: () {
                                // عند الضغط على المجموعة للانتقال
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupDetailsScreen(
                                      groupId: group['id'],
                                      levelId: widget.levelId,
                                      groupName: group['name'],
                                      teacherName: group['emp']?['name'] ?? "غير محدد",
                                      teacherId: group['emp']?['id'] ?? group['empId'] ?? 0,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  group['name'] ?? "---",
                                  style: TextStyle(
                                    color: kPrimaryBlue, // اللون الأزرق المعتمد في التصميم
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline, // خط تحت الكلمة لتبدو كلينك
                                    fontFamily: 'Almarai',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 2. خلية اسم الشيخ
                          DataCell(Text(group['emp']?['name'] ?? "---")),
                          // 3. خلية المكان
                          DataCell(Text(group['loc']?['name'] ?? "---")),
                          // 4. خلية عدد الطلاب
                          DataCell(Center(child: Text(group['studentCount']?.toString() ?? "0"))),
                          // 5. خلية المواعيد
                          DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: sessions.map((s) => Text(
                                        "${_getDayName(s['day'])} (${s['hour']})",
                                        style: const TextStyle(fontSize: 11)
                                    )).toList(),
                                  ),
                                ),
                              )
                          ),
                          // 6. خلية الحذف
                          DataCell(IconButton(
                              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(group['id'], group['name'])
                          )),
                        ]);
                      }).toList(),
                      // --- نهاية الجزء المعدل ---
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