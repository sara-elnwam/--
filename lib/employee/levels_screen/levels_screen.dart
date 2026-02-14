import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'level_one_screen.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  // دالة جلب المستويات من الـ API
  Future<List<dynamic>> fetchLevels() async {
    try {
      final response = await http.get(
        Uri.parse('https://nour-al-eman.runasp.net/api/Level/Getall'),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        if (decodedData['data'] is List) {
          return decodedData['data'];
        }
        return [];
      } else {
        throw 'خطأ في السيرفر: ${response.statusCode}';
      }
    } catch (e) {
      throw 'فشل الاتصال بالإنترنت: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kActiveBlue = Color(0xFF1976D2);
    const Color darkBlue = Color(0xFF2E3542);
    const Color orangeButton = Color(0xFFC66422);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_levels_main_unique",
        onPressed: () {
          // هنا يمكنك إضافة كود لفتح نافذة إضافة مستوى جديد
        },
        backgroundColor: orangeButton,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "إدارة المستويات",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                  color: darkBlue),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchLevels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: orangeButton));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text("حدث خطأ: ${snapshot.error}",
                          style: const TextStyle(fontFamily: 'Almarai')),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("لا توجد مستويات مضافة بعد"));
                  }

                  final levels = snapshot.data!;

                  return ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      return _buildLevelCard(
                          context,
                          levels[index]["name"] ?? "مستوى غير مسمى",
                          kActiveBlue,
                          darkBlue,
                          levels[index]["id"]
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, String title, Color primary, Color textCol, int id) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // الانتقال لشاشة المجموعات مع تمرير الـ ID الديناميكي من الـ API
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LevelOneScreen(
                levelId: id,
                levelName: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.layers_outlined, color: primary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                          color: textCol))),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}