import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionsScreen extends StatefulWidget {
  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isLoading = true;
  List<SessionRecord> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('user_id') ?? "6"; // الافتراضي 6 حسب الصور

      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Employee/GetSessionRecord?emp_id=$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _sessions = sessionRecordFromJson(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 10),
        _buildSessionsTable(),
      ],
    );
  }

  // كارد العنوان العلوي (جدول الشيخ)
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Text(
        "جدول الشيخ",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Almarai',
          color: Color(0xFF2E3542),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // الجدول المطابق للسكرين شوت
  Widget _buildSessionsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
          horizontalMargin: 15,
          columnSpacing: 25,
          columns: const [
            DataColumn(label: Text('اليوم', style: _headerStyle)),
            DataColumn(label: Text('الساعة', style: _headerStyle)),
            DataColumn(label: Text('المجموعة', style: _headerStyle)),
            DataColumn(label: Text('المستوى', style: _headerStyle)),
            DataColumn(label: Text('المكتب', style: _headerStyle)),
          ],
          rows: _buildRows(),
        ),
      ),
    );
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];
    for (var record in _sessions) {
      if (record.groupSessions != null) {
        for (var session in record.groupSessions!) {
          rows.add(DataRow(cells: [
            DataCell(Text(session.dayName, style: _cellStyle)),
            DataCell(Text(session.hour ?? "", style: _cellStyle)),
            DataCell(Text(record.name ?? "", style: _cellStyle)),
            DataCell(Text(record.level?.name ?? "", style: _cellStyle)),
            DataCell(Text(record.loc?.name ?? "", style: _cellStyle)),
          ]));
        }
      }
    }
    return rows;
  }

  static const TextStyle _headerStyle = TextStyle(
    fontFamily: 'Almarai',
    fontWeight: FontWeight.bold,
    color: Color(0xFF718096),
    fontSize: 13,
  );

  static const TextStyle _cellStyle = TextStyle(
    fontFamily: 'Almarai',
    color: Color(0xFF2E3542),
    fontSize: 13,
  );
}