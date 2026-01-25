import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart'; // استيراد مكتبة التحميل

// استيراد الشاشات الخاصة بالتطبيق
import 'login_screen.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';
import 'employee_home_screen.dart';

void main() async {
  // التأكد من تهيئة الـ Widgets قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة مكتبة التحميل لتفعيل الإشعارات والتحميل في الخلفية
  await FlutterDownloader.initialize(
      debug: true, // اجعليها false عند رفع التطبيق للمتجر نهائياً
      ignoreSsl: true // لتجنب مشاكل شهادات الأمان مع السيرفرات
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نور الإيمان',
      // إعدادات اللغة العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'AE')],
      locale: const Locale('ar', 'AE'),
      theme: ThemeData(
        fontFamily: 'Almarai',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC66422)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // التحقق من حالة تسجيل الدخول وتوجيه المستخدم للشاشة المناسبة
  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? loginDataString = prefs.getString('loginData');

    if (isLoggedIn && loginDataString != null) {
      try {
        final Map<String, dynamic> responseData = jsonDecode(loginDataString);
        final int userType = responseData['userType'] ?? responseData['type'] ?? 0;

        Widget nextScreen;
        if (userType == 2) {
          nextScreen = TeacherHomeScreen();
        } else if (userType == 1) {
          nextScreen = EmployeeHomeScreen();
        } else {
          nextScreen = StudentHomeScreen(loginData: responseData);
        }

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
        }
      } catch (e) {
        _navigateToLogin();
      }
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // حجم اللوجو 15% من عرض الشاشة بناءً على طلبك
                Image.asset(
                  'assets/full_logo.png',
                  width: MediaQuery.of(context).size.width * 0.15,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image, size: 25, color: Color(0xFFC66422)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}