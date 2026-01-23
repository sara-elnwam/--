import 'package:flutter/material.dart';

// الألوان المستخدمة لتوحيد التصميم
const Color kPrimaryBlue = Color(0xFF07427C);
const Color kTextDark = Color(0xFF2E3542);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

class StudentExamsWidget extends StatelessWidget {
  final List<dynamic> examsList;
  final bool isLoading;

  const StudentExamsWidget({super.key, required this.examsList, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryBlue));

    if (examsList.isEmpty) {
      return const Center(
          child: Text("لا توجد اختبارات متاحة حالياً", style: TextStyle(color: kLabelGrey))
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: examsList.length,
      itemBuilder: (context, index) {
        final data = examsList[index];
        final examInfo = data['exam'] ?? {};

        return Column(
          children: [
            // 1. كارت العنوان (اختبارات المستوى)
            _buildCustomCard(
              child: Text(
                "اختبارات المستوى ${examInfo['levelId'] ?? 'الأول'}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark),
              ),
            ),

            // 2. كارت تفاصيل الاختبار (الاسم والدرجة)
            _buildCustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _rowItem("اسم الاختبار:", examInfo['name'] ?? "غير محدد"),
                  const Divider(height: 30, color: kBorderColor),
                  _rowItem("درجة الطالب:", data['grade']?.toString() ?? "0"),
                ],
              ),
            ),

            // 3. كارت ملاحظات المعلم
            _buildCustomCard(
              child: _rowItem("ملاحظات المعلم:", data['note'] ?? "لا يوجد", isBlue: true),
            ),
          ],
        );
      },
    );
  }

  // تصميم الكارت الموحد
  Widget _buildCustomCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // تنسيق السطر الواحد (التسمية والقيمة) بدون أسهم
  Widget _rowItem(String label, String value, {bool isBlue = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: const TextStyle(color: kLabelGrey, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isBlue ? kPrimaryBlue : kTextDark,
          ),
        ),
      ],
    );
  }
}