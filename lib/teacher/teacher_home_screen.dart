import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/login_screen.dart';
import 'teacher_model.dart';

// --- الألوان المتوافقة مع الهوية البصرية للتطبيق ---
final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

// --- موديل مواعيد الدرس (منفصل وتلقائي) ---
List<SessionRecord> sessionRecordFromJson(String str) =>
    List<SessionRecord>.from(json.decode(str).map((x) => SessionRecord.fromJson(x)));

class SessionRecord {
  int? id;
  String? name;
  Level? level;
  Location? loc;
  List<GroupSession>? groupSessions;

  SessionRecord({this.id, this.name, this.level, this.loc, this.groupSessions});

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json["id"],
    name: json["name"],
    level: json["level"] == null ? null : Level.fromJson(json["level"]),
    loc: json["loc"] == null ? null : Location.fromJson(json["loc"]),
    groupSessions: json["groupSessions"] == null
        ? null
        : List<GroupSession>.from(json["groupSessions"].map((x) => GroupSession.fromJson(x))),
  );
}

class Level {
  String? name;
  Level({this.name});
  factory Level.fromJson(Map<String, dynamic> json) => Level(name: json["name"]);
}

class Location {
  String? name;
  Location({this.name});
  factory Location.fromJson(Map<String, dynamic> json) => Location(name: json["name"]);
}

class GroupSession {
  int? day;
  String? hour;
  GroupSession({this.day, this.hour});

  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(
    day: json["day"],
    hour: json["hour"],
  );

  String get dayName {
    switch (day) {
      case 1: return "السبت";
      case 2: return "الأحد";
      case 3: return "الإثنين";
      case 4: return "الثلاثاء";
      case 5: return "الأربعاء";
      case 6: return "الخميس";
      case 7: return "الجمعة";
      default: return "";
    }
  }
}

class TeacherHomeScreen extends StatefulWidget {
  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  String _currentTitle = "البيانات الشخصية";
  bool _isLoading = true;
  TeacherData? teacherData;
  List<SessionRecord> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_currentTitle == "البيانات الشخصية") {
      await _fetchTeacherProfile();
    } else if (_currentTitle == "مواعيد الدرس") {
      await _fetchSessions();
    }
  }

  Future<void> _fetchTeacherProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('user_id');
      if (id == null) return;
      final response = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetById?id=$id'));
      if (response.statusCode == 200) {
        final teacherModel = TeacherModel.fromJson(jsonDecode(response.body));
        setState(() => teacherData = teacherModel.data);
      }
    } catch (e) { debugPrint("Error: $e"); }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('user_id') ?? "6";
      final response = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetSessionRecord?emp_id=$id'));
      if (response.statusCode == 200) {
        setState(() => _sessions = sessionRecordFromJson(response.body));
      }
    } catch (e) { debugPrint("Error: $e"); }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildTeacherSidebar(context),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: kActiveBlue))
            : RefreshIndicator(
          onRefresh: _loadInitialData,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentTitle == "البيانات الشخصية") {
      return _buildProfileBody();
    } else if (_currentTitle == "مواعيد الدرس") {
      return _buildSessionsBody();
    }
    return Center(child: Text("قسم $_currentTitle", style: TextStyle(fontFamily: 'Almarai', color: darkBlue)));
  }

  // --- واجهة البيانات الشخصية (كما هي مع تحسينات طفيفة) ---
  Widget _buildProfileBody() {
    String rawDate = teacherData?.joinDate?.toString() ?? "---";
    String formattedDate = (rawDate != "---" && rawDate.length >= 10) ? rawDate.substring(0, 10) : rawDate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard("بيانات المعلم", Icons.badge_outlined, [
          _infoRow("اسم المعلم :", teacherData?.name ?? "---"),
          _infoRow("كود المعلم :", teacherData?.id?.toString() ?? "---"),
          _infoRow("المكتب التابع له :", teacherData?.loc?.name ?? "---"),
          _infoRow("موعد الالتحاق :", formattedDate),
          _infoRow("المؤهل الدراسي :", teacherData?.educationDegree ?? "---"),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("الدورات التدريبية", Icons.school_outlined, [
          if (teacherData?.courses == null || teacherData!.courses!.isEmpty)
            const Center(child: Text("لا توجد دورات", style: TextStyle(color: Colors.red, fontFamily: 'Almarai')))
          else
            ...teacherData!.courses!.map((course) => _infoRow("اسم الدورة :", course.toString())).toList(),
        ]),
      ],
    );
  }

  // --- واجهة مواعيد الدرس (نظام كروت بدون سكرول أفقي) ---
  Widget _buildSessionsBody() {
    // تجميع كل الجلسات في قائمة واحدة للعرض المباشر
    List<Widget> sessionWidgets = [];
    for (var record in _sessions) {
      if (record.groupSessions != null) {
        for (var session in record.groupSessions!) {
          sessionWidgets.add(_buildSessionCard(record, session));
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue, fontFamily: 'Almarai')),
        const SizedBox(height: 12),
        ...sessionWidgets,
      ],
    );
  }

  Widget _buildSessionCard(SessionRecord record, GroupSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge(session.dayName, kActiveBlue),
              Text(session.hour ?? "", style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue, fontSize: 16)),
            ],
          ),
          const Divider(height: 24, color: kBorderColor),
          _sessionDetailRow(Icons.groups_outlined, "المجموعة:", record.name ?? ""),
          const SizedBox(height: 8),
          _sessionDetailRow(Icons.layers_outlined, "المستوى:", record.level?.name ?? ""),
          const SizedBox(height: 8),
          _sessionDetailRow(Icons.location_on_outlined, "المكتب:", record.loc?.name ?? ""),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Almarai')),
    );
  }

  Widget _sessionDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kLabelGrey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 13, fontFamily: 'Almarai')),
        const SizedBox(width: 5),
        Expanded(child: Text(value, style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Almarai'))),
      ],
    );
  }

  // --- المكونات المساعدة للـ UI الأصلي ---
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: kActiveBlue, size: 22), const SizedBox(width: 10), Text(title, style: TextStyle(color: kActiveBlue, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Almarai'))])),
          const Divider(height: 1, color: kBorderColor),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 14, fontFamily: 'Almarai')), const SizedBox(width: 10), Expanded(child: Text(value, style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Almarai'), textAlign: TextAlign.left))]));
  }

  Widget _buildTeacherSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(padding: EdgeInsets.only(top: 40, bottom: 10), child: Center(child: Image.asset('assets/full_logo.png', height: 80, errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange)))),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(Icons.home_outlined, "الصفحة الرئيسية"),
                _buildSidebarItem(Icons.person_outline, "البيانات الشخصية"),
                _buildSidebarItem(Icons.fact_check_outlined, "الحضور و الإنصراف"),
                _buildSidebarItem(Icons.menu_book_outlined, "المنهج / المقرر"),
                _buildSidebarItem(Icons.groups_outlined, "المجموعات"),
                _buildSidebarItem(Icons.access_time, "مواعيد الدرس"),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.only(bottom: 100.0), child: _buildSidebarItem(Icons.logout, "تسجيل الخروج", color: Colors.redAccent, isLogout: true)),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {Color? color, bool isLogout = false}) {
    bool isSelected = _currentTitle == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kActiveBlue : (color ?? darkBlue)),
      title: Text(title, style: TextStyle(color: isSelected ? kActiveBlue : (color ?? darkBlue), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontFamily: 'Almarai')),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog();
        } else {
          setState(() {
            _currentTitle = title;
            _isLoading = true;
          });
          Navigator.pop(context);
          _loadInitialData();
        }
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
          content: Text("هل أنت متأكد؟", style: TextStyle(fontFamily: 'Almarai')),
          actions: [
            TextButton(child: Text("إلغاء"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
            },
              child: Text("خروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}