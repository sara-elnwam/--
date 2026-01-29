import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/login_screen.dart';
import 'teacher_model.dart';
import 'attendance_screen.dart'; // استيراد شاشة الحضور الجديدة
import 'package:project1/teacher/curriculum/curriculum_screen.dart'; // تأكد من المسار الصحيح لملفك
// --- الألوان الثابتة ---
final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

// --- موديل مواعيد الدرس ---
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

class Level { String? name; Level({this.name}); factory Level.fromJson(Map<String, dynamic> json) => Level(name: json["name"]); }
class Location { String? name; Location({this.name}); factory Location.fromJson(Map<String, dynamic> json) => Location(name: json["name"]); }
class GroupSession {
  int? day; String? hour;
  GroupSession({this.day, this.hour});
  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(day: json["day"], hour: json["hour"]);

  String get dayName {
    switch (day) {
      case 1: return "السبت"; case 2: return "الأحد"; case 3: return "الإثنين";
      case 4: return "الثلاثاء"; case 5: return "الأربعاء"; case 6: return "الخميس";
      case 7: return "الجمعة"; default: return "";
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
    } else if (_currentTitle == "المنهج / المقرر") {
      // أضف هذا السطر لإيقاف الدائرة فوراً لأن البيانات ثابتة
      setState(() => _isLoading = false);
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
        setState(() => teacherData = TeacherModel.fromJson(jsonDecode(response.body)).data);
      }
    } catch (e) { debugPrint(e.toString()); }
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
    } catch (e) { debugPrint(e.toString()); }
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
          elevation: 0.5,
          title: Text(_currentTitle, style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai', fontSize: 16)),
          centerTitle: true,
          iconTheme: IconThemeData(color: darkBlue),
        ),
        drawer: _buildTeacherSidebar(context),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: kActiveBlue))
              : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: KeyedSubtree(key: ValueKey(_currentTitle), child: _buildBody())
          ),
        ),
      ),
    );
  }
  Widget _buildBody() {
    if (_currentTitle == "البيانات الشخصية") return _buildProfileBody();
    if (_currentTitle == "مواعيد الدرس") return _buildSessionsBody();
    if (_currentTitle == "المنهج / المقرر") return CurriculumScreen(); // الربط هنا
    return Center(child: Text("قريباً: $_currentTitle", style: TextStyle(fontFamily: 'Almarai', color: darkBlue)));
  }
  // --- واجهة البيانات الشخصية ---
  Widget _buildProfileBody() {
    String formattedDate = "---";
    if (teacherData?.joinDate != null) {
      DateTime d = teacherData!.joinDate!;
      formattedDate = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
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
            ...teacherData!.courses!.map((c) => _infoRow("اسم الدورة :", c.toString())).toList(),
        ]),
      ],
    );
  }

  // --- واجهة مواعيد الدرس ---
  Widget _buildSessionsBody() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text("جدول الشيخ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue, fontFamily: 'Almarai')),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              columnSpacing: 25,
              headingRowHeight: 50,
              dataRowHeight: 60,
              headingRowColor: MaterialStateProperty.all(kActiveBlue.withOpacity(0.05)),
              columns: const [
                DataColumn(label: Text('اليوم', style: _headerStyle)),
                DataColumn(label: Text('الساعة', style: _headerStyle)),
                DataColumn(label: Text('المجموعة', style: _headerStyle)),
                DataColumn(label: Text('المستوى', style: _headerStyle)),
                DataColumn(label: Text('المكتب', style: _headerStyle)),
              ],
              rows: _buildSessionRows(),
            ),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildSessionRows() {
    List<DataRow> rows = [];
    for (var record in _sessions) {
      if (record.groupSessions != null) {
        for (var s in record.groupSessions!) {
          rows.add(DataRow(cells: [
            DataCell(Center(child: Text(s.dayName, style: _cellStyleBold))),
            DataCell(Center(child: Text(s.hour ?? "", style: _cellStyle))),
            DataCell(Center(child: Text(record.name ?? "", style: _cellStyle))),
            DataCell(Center(child: Text(record.level?.name ?? "", style: _cellStyle))),
            DataCell(Center(child: Text(record.loc?.name ?? "", style: _cellStyle))),
          ]));
        }
      }
    }
    return rows;
  }

  static const TextStyle _headerStyle = TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, color: kActiveBlue, fontSize: 14);
  static const TextStyle _cellStyle = TextStyle(fontFamily: 'Almarai', color: Color(0xFF2E3542), fontSize: 13);
  static const TextStyle _cellStyleBold = TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, color: Color(0xFF1976D2), fontSize: 13);

// --- السايدبار المطور للربط مع شاشة الحضور ---
  // ابحث عن هذه الدالة في ملف teacher_home_screen.dart وحدثها بهذا الكود
  Widget _buildTeacherSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            child: Center(
              child: Image.asset(
                'assets/full_logo.png',
                height: 80,
                errorBuilder: (c, e, s) => Icon(Icons.school, size: 60, color: primaryOrange),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem(Icons.home_outlined, "الرئيسية"),
                _buildSidebarItem(Icons.person_outline, "البيانات الشخصية"),

                // المنهج / المقرر (تأكد أن الاسم مطابق لما في _buildBody)
                _buildSidebarItem(Icons.menu_book_outlined, "المنهج / المقرر"),

                _buildSidebarItem(
                  Icons.fact_check_outlined,
                  "الحضور و الإنصراف",
                  isPushScreen: true,
                  screen: AttendanceScreen(),
                ),

                _buildSidebarItem(Icons.groups_outlined, "المجموعات"),
                _buildSidebarItem(Icons.access_time, "مواعيد الدرس"),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: _buildSidebarItem(
              Icons.logout,
              "تسجيل الخروج",
              color: Colors.redAccent,
              isLogout: true,
            ),
          ),
        ],
      ),
    );
  }
  // --- دالة بناء عنصر القائمة (Sidebar Item) ---
  Widget _buildSidebarItem(IconData icon, String title, {Color? color, bool isLogout = false, bool isPushScreen = false, Widget? screen}) {
    // تحديد ما إذا كان العنصر هو المختار حالياً لتغيير لونه (باستثناء الحالات الخاصة)
    bool isSelected = _currentTitle == title;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? kActiveBlue : (color ?? darkBlue),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? kActiveBlue : (color ?? darkBlue),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Almarai',
        ),
      ),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog(); // استدعاء ديالوج تسجيل الخروج
        } else if (isPushScreen && screen != null) {
          // فتح شاشة مستقلة (مثل شاشة الحضور) وإغلاق السايدبار
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        } else {
          // تبديل المحتوى داخل نفس الشاشة الرئيسية (Home)
          setState(() {
            _currentTitle = title;
            _isLoading = true;
          });
          Navigator.pop(context); // إغلاق السايدبار
          _loadInitialData(); // إعادة تحميل البيانات بناءً على التبويب الجديد
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
          title: const Text("تسجيل الخروج", style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
          content: const Text("هل أنت متأكد؟", style: TextStyle(fontFamily: 'Almarai')),
          actions: [
            TextButton(child: const Text("إلغاء"), onPressed: () => Navigator.pop(context)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => LoginScreen()), (r) => false);
              },
              child: const Text("خروج", style: TextStyle(color: Colors.white, fontFamily: 'Almarai')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [Icon(icon, color: kActiveBlue, size: 22), const SizedBox(width: 10), Text(title, style: TextStyle(color: kActiveBlue, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Almarai'))]),
          ),
          const Divider(height: 1, color: kBorderColor),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLabelGrey, fontSize: 14, fontFamily: 'Almarai')),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Almarai'), textAlign: TextAlign.left)),
        ],
      ),
    );
  }
}