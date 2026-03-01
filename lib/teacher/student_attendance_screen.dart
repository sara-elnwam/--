import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

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
  static const Color kDarkBlue = Color(0xFF07427C);
  static const Color kOrange   = Color(0xFFC66422);
  static const Color kBg       = Color(0xFFF4F6FA);
  static const Color kBorder   = Color(0xFFDDE3EE);

  bool _isLoading = false;
  bool _isSaving  = false;

  // history قبل النهارده
  Map<int, List<Map<String, dynamic>>> _historyByStudent = {};

  // الفورم الحالي
  late List<Map<String, dynamic>> _newEntries;

  final List<String> _ratingOptions = ["ممتاز", "جيد جدا", "جيد", "مقبول", "ضعيف"];

  @override
  void initState() {
    super.initState();
    // نبدأ بقائمة فاضية ريح لحد ما يييجي الداتا
    _newEntries = widget.students.map((s) => _emptyEntry(s)).toList();
    _fetchAndFillForm();
  }

  Map<String, dynamic> _emptyEntry(Student s) => {
    "stId"   : s.id,
    "name"   : s.name,
    "status" : false,
    "oldSave": null,
    "newSave": null,
    "note"   : "",
    "points" : "",
  };

  // ============================================================
  // ✅ المنطق الأساسي: نجيب الداتا ونملي الفورم
  // ============================================================
  Future<void> _fetchAndFillForm() async {
    setState(() => _isLoading = true);
    try {
      final url = "https://nour-al-eman.runasp.net/api/Group/GetGroupAttendace?GroupId=${widget.groupId}";
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) return;

      final List raw = json.decode(res.body)["data"] ?? [];

      // ✅ نجيب تاريخ النهارده بصيغة "yyyy-MM-dd" من غير توقيت
      // السيرفر بيخزن local time، فبنقارن الـ date part بس
      final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // آخر سجل لكل طالب النهارده (بـ id الأكبر)
      final Map<int, Map<String, dynamic>> todayLatest = {};
      // كل السجلات قبل النهارده
      final Map<int, List<Map<String, dynamic>>> history = {};

      for (final item in raw) {
        final int stId       = item["studentId"] ?? 0;
        final String? dateStr = item["createDate"]; // "2026-02-23T01:37:58.85"
        if (dateStr == null) continue;

        // ✅ نقارن الـ date part فقط (أول 10 حروف)
        final String itemDate = dateStr.substring(0, 10); // "2026-02-23"
        final bool isToday = itemDate == todayDate;

        if (isToday) {
          // نحتفظ بالأحدث (أكبر id)
          final int currentId  = item["id"] ?? 0;
          final int existingId = todayLatest[stId]?["_id"] ?? -1;
          if (currentId > existingId) {
            todayLatest[stId] = {
              "_id"    : currentId,
              "present": item["isPresent"] ?? false,
              "oldSave": _toRating(item["oldAttendanceNote"]),
              "newSave": _toRating(item["newAttendanceNote"]),
              "note"   : item["note"] ?? "",
              "points" : (item["points"] ?? 0).toString(),
            };
          }
        } else {
          history.putIfAbsent(stId, () => []);
          history[stId]!.add({
            "isPresent"        : item["isPresent"] ?? false,
            "oldAttendanceNote": _toRating(item["oldAttendanceNote"]),
            "newAttendanceNote": _toRating(item["newAttendanceNote"]),
            "note"             : item["note"] ?? "",
            "points"           : item["points"] ?? 0,
            "createDate"       : dateStr,
          });
        }
      }

      // ✅ نملي الفورم:
      // - لو عنده سجل النهارده → حط آخر حالة
      // - لو ملهوش → غياب تلقائي
      setState(() {
        _historyByStudent = history;
        _newEntries = widget.students.map((s) {
          final rec = todayLatest[s.id];
          if (rec != null) {
            return {
              "stId"   : s.id,
              "name"   : s.name,
              "status" : rec["present"],
              "oldSave": rec["oldSave"],
              "newSave": rec["newSave"],
              "note"   : rec["note"],
              "points" : rec["points"],
            };
          }
          return _emptyEntry(s); // غياب
        }).toList();
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // ✅ الحفظ: نبعت للسيرفر، وبعدين نرفرش
  // ============================================================
  Future<void> _saveNewRecords() async {
    setState(() => _isSaving = true);

    final payload = _newEntries.map((s) => {
      "id"               : 0,
      "studentId"        : s["stId"],
      "groupId"          : widget.groupId,
      "isPresent"        : s["status"],
      "points"           : int.tryParse(s["points"]?.toString() ?? "0") ?? 0,
      "note"             : s["note"] ?? "",
      "newAttendanceNote": _toIndex(s["newSave"]),
      "oldAttendanceNote": _toIndex(s["oldSave"]),
      "createDate"       : DateTime.now().toIso8601String(),
      "createBy"         : "Teacher",
      "createFrom"       : "Mobile",
    }).toList();

    try {
      final res = await http.post(
        Uri.parse("https://nour-al-eman.runasp.net/api/StudentAttendance/submit"),
        headers: {"accept": "*/*", "Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showToast("✅ تم الحفظ بنجاح", kDarkBlue);
        // ✅ الفورم يفضل زي ما هو - الـ checkboxes والتقييمات مش بتتغير
        // بس نرفرش الـ history section في الخلفية بس
        _fetchHistoryOnly();
      } else {
        _showToast("❌ خطأ: ${res.statusCode}", Colors.red);
        debugPrint("Save error body: ${res.body}");
      }
    } catch (e) {
      _showToast("❌ فشل الاتصال", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  // ✅ بيرفرش الـ history فقط من غير ما يلمس الفورم
  Future<void> _fetchHistoryOnly() async {
    try {
      final url = "https://nour-al-eman.runasp.net/api/Group/GetGroupAttendace?GroupId=${widget.groupId}";
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return;

      final List raw = json.decode(res.body)["data"] ?? [];
      final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final Map<int, List<Map<String, dynamic>>> history = {};
      for (final item in raw) {
        final int stId        = item["studentId"] ?? 0;
        final String? dateStr = item["createDate"];
        if (dateStr == null) continue;
        final bool isToday = dateStr.substring(0, 10) == todayDate;
        if (!isToday) {
          history.putIfAbsent(stId, () => []);
          history[stId]!.add({
            "isPresent"        : item["isPresent"] ?? false,
            "oldAttendanceNote": _toRating(item["oldAttendanceNote"]),
            "newAttendanceNote": _toRating(item["newAttendanceNote"]),
            "note"             : item["note"] ?? "",
            "points"           : item["points"] ?? 0,
            "createDate"       : dateStr,
          });
        }
      }
      if (mounted) setState(() => _historyByStudent = history);
    } catch (e) {
      debugPrint("History fetch error: $e");
    }
  }
  String? _toRating(dynamic index) {
    if (index == null) return null;
    int i = (index is int) ? index : int.tryParse(index.toString()) ?? 0;
    if (i < 1 || i > _ratingOptions.length) return null;
    return _ratingOptions[i - 1];
  }

  int _toIndex(String? rating) {
    if (rating == null) return 0;
    int i = _ratingOptions.indexOf(rating);
    return i != -1 ? i + 1 : 0;
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Almarai')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        bottomNavigationBar: _buildSaveButton(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kDarkBlue))
            : Column(
          children: [
            _buildFormSection(),
            const SizedBox(height: 8),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  // ===== جدول الإدخال =====
  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // هيدر
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            decoration: const BoxDecoration(
              color: kDarkBlue,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 5, child: _HCell("اسم الطالب")),
                Expanded(flex: 2, child: _HCell("الحضور")),
                Expanded(flex: 4, child: _HCell("حفظ قديم")),
                Expanded(flex: 4, child: _HCell("حفظ جديد")),
                Expanded(flex: 3, child: _HCell("تعليق")),
              ],
            ),
          ),
          // صفوف
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newEntries.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
            itemBuilder: (_, i) => _buildRow(i),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int i) {
    final entry   = _newEntries[i];
    final present = entry["status"] == true;
    final hasNote = entry["note"]?.toString().trim().isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      child: Row(
        children: [
          // اسم الطالب
          Expanded(
            flex: 5,
            child: Text(entry["name"],
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340), fontFamily: 'Almarai'),
                overflow: TextOverflow.ellipsis),
          ),

          // checkbox
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: present,
                  activeColor: kDarkBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() {
                    _newEntries[i]["status"] = v;
                    if (v == false) {
                      _newEntries[i]["oldSave"] = null;
                      _newEntries[i]["newSave"] = null;
                    }
                  }),
                ),
              ),
            ),
          ),

          // حفظ قديم
          Expanded(flex: 4, child: _ratingDrop(i, "oldSave", present)),

          // حفظ جديد
          Expanded(flex: 4, child: _ratingDrop(i, "newSave", present)),

          // تعليق
          Expanded(
            flex: 3,
            child: Center(
              child: InkWell(
                onTap: present ? () => _showNoteDialog(i) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: present
                        ? (hasNote
                        ? kDarkBlue.withOpacity(0.12)
                        : kBg)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasNote ? Icons.comment : Icons.comment_outlined,
                    size: 20,
                    color: present
                        ? (hasNote ? kDarkBlue : Colors.grey.shade400)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingDrop(int i, String key, bool enabled) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _newEntries[i][key],
        isExpanded: true,
        hint: Text("—",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF1A2340),
            fontFamily: 'Almarai'),
        iconSize: 14,
        onChanged: enabled
            ? (val) => setState(() => _newEntries[i][key] = val)
            : null,
        items: _ratingOptions
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    );
  }

  // ===== زر الحفظ الثابت =====
  Widget _buildSaveButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -3))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _isSaving ? null : _saveNewRecords,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded,
                color: Colors.white, size: 18),
            label: Text(
              _isSaving ? "جاري الحفظ..." : "حفظ التعديلات",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Almarai'),
            ),
          ),
        ),
      ),
    );
  }

  // ===== History السابق =====
  Widget _buildHistorySection() {
    if (_historyByStudent.isEmpty) return const SizedBox.shrink();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: const [
                Icon(Icons.history_rounded, size: 16, color: kDarkBlue),
                SizedBox(width: 6),
                Text("سجل الحضور السابق",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kDarkBlue,
                        fontFamily: 'Almarai')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: widget.students.length,
              itemBuilder: (_, si) {
                final st      = widget.students[si];
                final records = _historyByStudent[st.id] ?? [];
                if (records.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    childrenPadding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: kDarkBlue.withOpacity(0.1),
                      child: Text(
                        st.name.isNotEmpty ? st.name[0] : "?",
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kDarkBlue),
                      ),
                    ),
                    title: Text(st.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2340),
                            fontFamily: 'Almarai')),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kDarkBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("${records.length} سجل",
                          style: const TextStyle(
                              fontSize: 11,
                              color: kDarkBlue,
                              fontWeight: FontWeight.bold)),
                    ),
                    children: records
                        .map((rec) => _buildHistoryCard(rec))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> rec) {
    final bool present = rec["isPresent"] == true;
    String dateStr = "--";
    try {
      if (rec["createDate"] != null) {
        final d = DateTime.parse(rec["createDate"]);
        dateStr = DateFormat("yyyy/MM/dd – hh:mm a").format(d);
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(
              color: present
                  ? const Color(0xFF2E7D32)
                  : Colors.red.shade300,
              width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  present
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 15,
                  color: present
                      ? const Color(0xFF2E7D32)
                      : Colors.red),
              const SizedBox(width: 5),
              Text(
                present ? "حضور" : "غياب",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: present
                        ? const Color(0xFF2E7D32)
                        : Colors.red),
              ),
              const Spacer(),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
            ],
          ),
          if (present) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(
                    label: "حفظ قديم",
                    value: rec["oldAttendanceNote"] ?? "--",
                    color: kDarkBlue),
                const SizedBox(width: 6),
                _Chip(
                    label: "حفظ جديد",
                    value: rec["newAttendanceNote"] ?? "--",
                    color: kOrange),
                const SizedBox(width: 6),
                _Chip(
                    label: "نقاط",
                    value: "${rec["points"] ?? 0}",
                    color: const Color(0xFF2E7D32)),
              ],
            ),
            if (rec["note"]?.toString().trim().isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.comment_outlined,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(rec["note"],
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ===== ديالوج التعليق =====
  void _showNoteDialog(int i) {
    final noteCtrl   =
    TextEditingController(text: _newEntries[i]["note"]);
    final pointsCtrl = TextEditingController(
        text: _newEntries[i]["points"]?.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text("تعليق ونقاط",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kDarkBlue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField("التعليق", noteCtrl, maxLines: 3),
              const SizedBox(height: 12),
              _dialogField("النقاط", pointsCtrl,
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء",
                  style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kDarkBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                setState(() {
                  _newEntries[i]["note"]   = noteCtrl.text;
                  _newEntries[i]["points"] = pointsCtrl.text;
                });
                Navigator.pop(context);
              },
              child: const Text("حفظ",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: kDarkBlue,
                fontFamily: 'Almarai')),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: "اكتب هنا...",
            filled: true,
            fillColor: kBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}

// ========== Widgets مساعدة ==========

class _HCell extends StatelessWidget {
  final String text;
  const _HCell(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            fontFamily: 'Almarai')),
  );
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Chip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Flexible(
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 9, color: color.withOpacity(0.8))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    ),
  );
}