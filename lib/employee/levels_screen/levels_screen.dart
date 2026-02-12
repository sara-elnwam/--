import 'package:flutter/material.dart';
import 'level_one_screen.dart'; // تأكدي أن المسار صحيح

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color kActiveBlue = Color(0xFF1976D2);
    const Color darkBlue = Color(0xFF2E3542);
    const Color orangeButton = Color(0xFFC66422);

    final List<Map<String, dynamic>> levels = [
      {"id": 1, "name": "المستوى الأول"},
      {"id": 2, "name": "المستوى الثاني"},
      {"id": 3, "name": "المستوى الثالث"},
      {"id": 4, "name": "المستوى الرابع"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_levels_main_unique",
        onPressed: () {},
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
              child: ListView.builder(
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  return _buildLevelCard(
                      context,
                      levels[index]["name"],
                      kActiveBlue,
                      darkBlue,
                      levels[index]["id"]
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
          // هنا بنبعت الـ id والـ name للشاشة التانية عشان تفتح صح
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