import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class StudentCoursesWidget extends StatefulWidget {
  final List<dynamic> coursesList;
  final bool isLoading;

  const StudentCoursesWidget({super.key, required this.coursesList, required this.isLoading});

  @override
  State<StudentCoursesWidget> createState() => _StudentCoursesWidgetState();
}

class _StudentCoursesWidgetState extends State<StudentCoursesWidget> {
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      if (mounted) setState(() {});
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  Future<void> _downloadFile(dynamic course) async {
    await [Permission.storage, Permission.notification].request();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final String levelId = course['levelId']?.toString() ?? "1";
      final String typeId = course['typeId']?.toString() ?? "3";
      final String finalUrl = "https://nour-al-eman.runasp.net/api/StudentCources/DownloadLatest?levelId=$levelId&typeId=$typeId";

      String savePath = "/storage/emulated/0/Download";
      String fileName = "${course['name'] ?? 'file'}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      await FlutterDownloader.enqueue(
        url: finalUrl,
        savedDir: savePath,
        fileName: fileName,
        headers: {
          "Authorization": "Bearer $token",
          "User-Agent": "Mozilla/5.0",
          "Accept": "*/*",
        },
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      _showSnackBar("⏳ بدأ التحميل.. تابع الستارة", isError: false);
    } catch (e) {
      _showSnackBar("❌ فشل في بدء التحميل");
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Almarai')),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF07427C)));
    }

    if (widget.coursesList.isEmpty) {
      return const Center(child: Text("لا توجد ملفات متاحة حالياً"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.coursesList.length,
      itemBuilder: (context, index) {
        final course = widget.coursesList[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            // الـ Row في فلاتر بيعكس ترتيب العناصر تلقائياً بناءً على اتجاه اللغة
            // يعني أول عنصر في الكود هيكون في اليمين لو عربي، وفي الشمال لو إنجليزي
            children: [
              // 1. قسم النصوص (الإسم والتفاصيل) - هو الأول عشان يظهر في جهة "بداية" اللغة
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // بيبدأ من اليمين في العربي والشمال في الإنجليزي
                  children: [
                    _buildInfoRow("الإسم", course['name'] ?? "غير متوفر"),
                    const SizedBox(height: 8),
                    _buildInfoRow("التفاصيل", course['description'] ?? "لا يوجد وصف"),
                  ],
                ),
              ),

              const Spacer(), // بيخلق فراغ في النص عشان يزق زرار التحميل للطرف التاني

              // 2. قسم زر التحميل - هيظهر في جهة "نهاية" اللغة (شمال في العربي، يمين في الإنجليزي)
              InkWell(
                onTap: () => _downloadFile(course),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ترتيب الأيقونة والكلمة جوه الزرار كمان هيتعكس لوحده
                      const Icon(Icons.download_outlined, color: Color(0xFFC66422), size: 24),
                      const SizedBox(width: 4),
                      const Text(
                        "تحميل",
                        style: TextStyle(
                          color: Color(0xFFC66422),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: 'Almarai',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2E3542),
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'Almarai',
          ),
        ),
      ],
    );
  }
}