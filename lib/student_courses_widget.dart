import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentCoursesWidget extends StatelessWidget {
  final List<dynamic> coursesList;
  final bool isLoading;

  const StudentCoursesWidget({super.key, required this.coursesList, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)));
    if (coursesList.isEmpty) return const Center(child: Text("لا توجد مقررات حالياً"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coursesList.length,
      itemBuilder: (context, index) {
        final course = coursesList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            // هنا استخدمنا الترتيب الطبيعي ليكون مرناً مع لغة الجهاز
            children: [
              // نصوص المقرر تأخذ المساحة الأكبر
              Expanded(
                child: Column(
                  // هذه الخاصية تجعل النص يبدأ من "البداية" حسب لغة الموبايل
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الإسم: ${course['name']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E3542),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "التفاصيل: ${course['description']}",
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // زر التحميل يكون في الطرف الآخر
              TextButton.icon(
                onPressed: () async {
                  if (course['url'] != null) {
                    final fullUrl = "https://nour-al-eman.runasp.net${course['url']}";
                    if (await canLaunchUrl(Uri.parse(fullUrl))) {
                      await launchUrl(Uri.parse(fullUrl));
                    }
                  }
                },
                icon: const Icon(Icons.download, size: 18, color: Colors.orange),
                label: const Text(
                  "تحميل",
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}