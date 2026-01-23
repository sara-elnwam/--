import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// تأكدي من عمل import لملف الموديل هنا
 import 'task_model.dart';

class StudentTasksWidget extends StatelessWidget {
  final List<Datum> tasksList; // استخدام نوع البيانات من الموديل
  final bool isLoading;

  const StudentTasksWidget({super.key, required this.tasksList, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)));
    if (tasksList.isEmpty) return const Center(child: Text("لا توجد أعمال حالياً"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasksList.length,
      itemBuilder: (context, index) {
        final item = tasksList[index];

        // الوصول للبيانات أصبح أسهل عن طريق النقطة . بدل الـ [ ]
        final studentExam = (item.studentExams != null && item.studentExams!.isNotEmpty)
            ? item.studentExams![0]
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? "بدون عنوان",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E3542)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description ?? "",
                          style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (item.url != null) {
                        final fullUrl = "https://nour-al-eman.runasp.net${item.url}";
                        if (await canLaunchUrl(Uri.parse(fullUrl))) {
                          await launchUrl(Uri.parse(fullUrl));
                        }
                      }
                    },
                    icon: const Icon(Icons.download_for_offline, color: Colors.orange, size: 28),
                  ),
                ],
              ),
              if (studentExam != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _badge("الدرجة: ${studentExam.grade ?? 'لم ترصد'}", Colors.green),
                    _badge("ملاحظة: ${studentExam.note ?? 'لا يوجد'}", Colors.blueGrey),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}