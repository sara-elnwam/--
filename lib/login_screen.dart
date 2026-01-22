import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';
import 'employee_home_screen.dart';

final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
final Color greyText = Color(0xFF707070);
final Color successGreen = Color(0xFF2D8A63);

const String baseUrl = 'https://nour-al-eman.runasp.net/api';

var logger = Logger();

void main() async { // لاحظي إضافة async هنا
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final String? loginDataString = prefs.getString('loginData');

  Widget initialScreen = LoginScreen();

  if (isLoggedIn && loginDataString != null) {
    try {
      final Map<String, dynamic> responseData = jsonDecode(loginDataString);
      final int userType = responseData['userType'] ?? 0;
      if (userType == 2) {
        initialScreen = TeacherHomeScreen();
      } else if (userType == 1) {
        initialScreen = EmployeeHomeScreen();
      } else {
        initialScreen = StudentHomeScreen(loginData: responseData);
      }
    } catch (e) {
      initialScreen = LoginScreen();
    }
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Almarai',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2E3542)),
        titleTextStyle: TextStyle(color: Color(0xFF2E3542), fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    home: initialScreen,
  ));
}

Route _createRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutQuart;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
    transitionDuration: Duration(milliseconds: 600),
  );
}

class SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: successGreen),
              SizedBox(height: 20),
              Text('تم تسجيل الحساب بنجاح',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: successGreen),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text('برجاء الانتظار حتى يقوم المشرف بالموافقة على الحساب',
                style: TextStyle(fontSize: 16, color: darkBlue),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('العودة لتسجيل الدخول', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      try {
        final String phone = _phoneController.text.trim();
        final String password = _passwordController.text;

        final response = await http.post(
          Uri.parse('$baseUrl/Account/ValidateUserLogin'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "Phone": phone,
            "Password": password,
            "UserId": "" // السيرفر يطلبه كحقل إجباري
          }),
        );

        logger.v("LOGIN_RESPONSE: Code ${response.statusCode} | Body: ${response.body}");

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          Map<String, dynamic>? responseData;
          final prefs = await SharedPreferences.getInstance();

          if (responseBody is List) {
            // إذا كانت List، نأخذ العنصر الأول (المستخدم الأول)
            if (responseBody.isNotEmpty) {
              responseData = Map<String, dynamic>.from(responseBody[0] as Map);
            } else {
              _showErrorSnackBar("لا يوجد مستخدم بهذه البيانات");
              return;
            }
          } else if (responseBody is Map) {
            // إذا كانت Map، نستخدمها مباشرة مع تحويل الأنواع
            responseData = Map<String, dynamic>.from(responseBody);
          } else {
            _showErrorSnackBar("استجابة غير صحيحة من السيرفر");
            return;
          }



          await prefs.setString('loginData', jsonEncode(responseData));
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_token', responseData!['token'] ?? "");
          // حفظ student_id كـ string، واستخدام 'id' بدلاً من 'userId'
          await prefs.setString('student_id', responseData['id']?.toString() ?? "");
          if (responseData['data'] != null) {
            await prefs.setString('student_id', responseData['data']['id']?.toString() ?? "");
          }

          // استخدام 'userType' بدلاً من 'type'
          final int userType = responseData['userType'] ?? 0;
          String studentId = "";
          Widget nextScreen;
          if (userType == 2) {
            nextScreen = TeacherHomeScreen();
          } else if (userType == 1) {
            nextScreen = EmployeeHomeScreen();
          } else {
            nextScreen = StudentHomeScreen(loginData: responseData);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("تم تسجيل الدخول بنجاح"), backgroundColor: successGreen),
            );
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
          }

        } else if (response.statusCode == 401) {
          _showErrorSnackBar("خطأ في الهاتف أو كلمة السر");
        } else {
          _showErrorSnackBar("حدث خطأ ما: ${response.statusCode}");
        }
      } catch (e) {
        logger.e("LOGIN_ERROR: $e");
        _showErrorSnackBar("خطأ في الاتصال بالسيرفر");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/full_logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.school, size: 80, color: primaryOrange),
                        ),
                        SizedBox(height: 15),
                        Text('تسجيل الدخول',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue)),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildSimpleLabel("رقم الهاتف", isRequired: true),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _buildInputDecoration("أدخل رقم الهاتف"),
                    keyboardType: TextInputType.phone,
                    validator: (value) => (value == null || value.isEmpty) ? "مطلوب" : null,
                  ),
                  SizedBox(height: 20),
                  _buildSimpleLabel("كلمه السر", isRequired: true),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscured,
                    decoration: _buildInputDecoration("أدخل كلمة السر").copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Color(0xFF9E9E9E)),
                        onPressed: () => setState(() => _isObscured = !_isObscured),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? "مطلوب" : null,
                  ),
                  SizedBox(height: 25),
                  _isLoading
                      ? Center(child: CircularProgressIndicator(color: primaryOrange))
                      : _buildPrimaryButton(context, "الدخول", _handleLogin),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(' ليس لديك حساب ؟ ', style: TextStyle(fontSize: 14, color: greyText)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, _createRoute(UserTypeScreen())),
                        child: Text('انشاء حساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkBlue, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Text(text, style: TextStyle(fontSize: 14, color: darkBlue, fontWeight: FontWeight.w600)),
        if (isRequired) Text(' *', style: TextStyle(color: Colors.red))
      ]),
    );
  }
}

class UserTypeScreen extends StatefulWidget {
  @override
  _UserTypeScreenState createState() => _UserTypeScreenState();
}

class _UserTypeScreenState extends State<UserTypeScreen> {
  String? selectedType;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: darkBlue), onPressed: () => Navigator.pop(context)),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('انضم إلينا', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkBlue)),
              SizedBox(height: 8),
              Text('اختر نوع الحساب للمتابعة', style: TextStyle(fontSize: 16, color: greyText)),
              SizedBox(height: 40),
              _buildTypeCard('طالب', 'للتسجيل في الدورات ومتابعة الدروس', Icons.school_rounded, 'student'),
              SizedBox(height: 20),
              _buildTypeCard('موظف', 'لإدارة النظام والمحتوى التعليمي', Icons.work_rounded, 'employee'),
              Spacer(),
              if (selectedType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: _buildPrimaryButton(context, "التالي", () {
                    if (selectedType == 'student') Navigator.push(context, _createRoute(StudentRegistrationScreen()));
                    else Navigator.push(context, _createRoute(EmployeeRegistrationScreen()));
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(String title, String desc, IconData icon, String type) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? primaryOrange : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? primaryOrange : Colors.grey.shade100, shape: BoxShape.circle), child: Icon(icon, color: isSelected ? Colors.white : darkBlue)),
            SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBlue)), Text(desc, style: TextStyle(fontSize: 13, color: greyText))])),
            if (isSelected) Icon(Icons.check_circle, color: primaryOrange),
          ],
        ),
      ),
    );
  }
}

Future<void> _handleRegistration({
  required BuildContext context,
  required Map<String, dynamic> data,
}) async {
  try {
    logger.i("API_REQUEST: RegisterUser | Data: ${jsonEncode(data)}");
    final response = await http.post(
      Uri.parse('$baseUrl/Account/RegisterUser'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    // طباعة استجابة التسجيل بالكامل
    logger.v("API_RESPONSE: Code ${response.statusCode} | Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String userIdFromResponse = responseData['userId'].toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', responseData['token'] ?? "");
        await prefs.setString('student_id', responseData['userId']?.toString() ?? "");
        await prefs.setString('registered_user_id', userIdFromResponse);
        // حفظ كامل البيانات ليتمكن التطبيق من قراءتها عند الفتح مرة أخرى
        await prefs.setString(
            'loginData', jsonEncode(responseData)); // <--- إضافة هذا السطر
        await prefs.setBool('is_logged_in', true);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SuccessScreen()));
      }
    }else {
      logger.e("API_ERROR: ${response.statusCode} | Body: ${response.body}");

      String displayError = "فشل التسجيل: تفقد البيانات المدخلة";
      try {
        var body = jsonDecode(response.body);
        if (body['message'] != null) {
          displayError = body['message'].toString();
        } else if (body['error'] != null) {
          displayError = body['error'].toString();
        } else if (body['errors'] != null) {
          displayError = "يرجى مراجعة الحقول المطلوبة";
        }
      } catch(_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayError), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
      );
    }
  } catch (e) {
    logger.e("CONNECTION_ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("خطأ في الاتصال بالإنترنت"), backgroundColor: Colors.red),
    );
  }
}

class StudentRegistrationScreen extends StatefulWidget {
  @override
  _StudentRegistrationScreenState createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _parentJobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String? _selectedLocation;
  String? _selectedAttendance;

  final Map<String, int> locationMap = {
    "مدرسة نور الإيمان": 1,
    "rouby's location": 2,
    "مسجد الشيخ ابراهيم": 3,
    "مسجد العباسي": 4,
    "مسجد الهدى والنور": 5,
    "مضيفة نافع": 6,
    "مكتب الموقف": 7,
  };
  void _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("كلمات السر غير متطابقة"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      String birthDate = "${_yearController.text}-${_monthController.text.padLeft(2, '0')}-${_dayController.text.padLeft(2, '0')}T00:00:00.000Z";

      Map<String, dynamic> studentData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim().isEmpty ? "00000000000" : _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "ParentJob": _parentJobController.text.trim(),  // تغيير إلى ParentJob (حرف كبير)
        "email": _emailController.text.trim(),
        "governmentSchool": _schoolController.text.trim(),
        "attendanceType": _selectedAttendance ?? "أوفلاين",
        "birthDate": birthDate,
        "locId": locationMap[_selectedLocation] ?? 1,
        "phone2": _parentPhoneController.text.trim(),
        "ssn": "",
        "employeeTypeId": 0,  // 0 للطالب (ليس null، ليتم تصنيفه صحيحًا)
        "educationDegree": "",
        "Password": _passwordController.text,  // تغيير إلى Password (حرف كبير)
        // joinDate: DateTime.now().toIso8601String(),  // أضفه إذا لزم الأمر، لكن السيرفر ربما يضيفه تلقائيًا
      };

      logger.i("SENDING STUDENT DATA: ${jsonEncode(studentData)}");
      await _handleRegistration(context: context, data: studentData);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseRegistrationScreen(
      formKey: _formKey,
      title: 'إنشاء حساب طالب',
      buttonText: "انشاء حساب",
      isLoading: _isLoading,
      onButtonPressed: _registerStudent,
      children: [
        _buildInputField("الإسم", "الإسم", controller: _nameController),
        _buildInputField("وظيفة الأب", "وظيفة الأب", isRequired: false, controller: _parentJobController),
        _buildDropdownField("المكتب التابع له", locationMap.keys.toList(), onChanged: (val) => _selectedLocation = val),
        _buildInputField("العنوان", "العنوان", controller: _addressController),
        _buildInputField("البريد الإلكتروني", "example@mail.com", isRequired: true, controller: _emailController),
        _buildBirthdayRow(dayCtrl: _dayController, monthCtrl: _monthController, yearCtrl: _yearController),
        _buildInputField("رقم هاتف ولي الأمر", "01xxxxxxxxx", isPhone: true, isRequired: true, controller: _parentPhoneController),
        _buildInputField("رقم الهاتف (اختياري)", "01xxxxxxxxx", isPhone: true, isRequired: false, controller: _phoneController),
        _buildInputField("اسم المدرسة الحكومية", "اسم المدرسة", controller: _schoolController),
        _buildDropdownField("الحضور", ["أونلاين", "أوفلاين"], onChanged: (val) => _selectedAttendance = val),
        _buildInputField("كلمة السر", "كلمة السر", isPassword: true, isObscured: _isPasswordObscured, onToggle: () => setState(() => _isPasswordObscured = !_isPasswordObscured), controller: _passwordController),
        _buildInputField("تأكيد كلمة السر", "تأكيد كلمة السر", isPassword: true, isObscured: _isConfirmObscured, onToggle: () => setState(() => _isConfirmObscured = !_isConfirmObscured), controller: _confirmPasswordController),
      ],
    );
  }
}

class EmployeeRegistrationScreen extends StatefulWidget {
  @override
  _EmployeeRegistrationScreenState createState() => _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState extends State<EmployeeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ssnController = TextEditingController();
  final TextEditingController _eduController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedJobTitle;
  String? _selectedLocation;

  final Map<String, int> locationMap = {
    "مدرسة نور الإيمان": 1,
    "rouby's location": 2,
    "مسجد الشيخ ابراهيم": 3,
    "مسجد العباسي": 4,
    "مسجد الهدى والنور": 5,
    "مضيفة نافع": 6,
    "مكتب الموقف": 7,
  };

  final Map<String, int> jobTypeMap = {
    "معلم/معلمة": 1,
    "إدارة": 2,
    "محاسب": 3,
  };


  void _registerEmployee() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("كلمات السر غير متطابقة"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      int empTypeId = jobTypeMap[_selectedJobTitle] ?? 1;
      int userType = (empTypeId == 1) ? 2 : 1;  // إذا معلم (1)، type=2؛ إلا ذلك، type=1

      Map<String, dynamic> employeeData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": "",  // فارغ كما في السيرفر
        "ParentJob": "",  // فارغ كما في السيرفر
        "email": _emailController.text.trim(),
        "governmentSchool": "",  // فارغ كما في السيرفر
        "attendanceType": "",  // فارغ كما في السيرفر
        "birthDate": DateTime.now().toIso8601String(),  // افتراضي كما في السيرفر
        "locId": locationMap[_selectedLocation] ?? 1,
        "phone2": "",  // فارغ كما في السيرفر
        "ssn": _ssnController.text.trim(),
        "employeeTypeId": empTypeId,  // 1=معلم، 2=إدارة، 3=محاسب
        "educationDegree": _eduController.text.trim(),
        "Password": _passwordController.text,  // Password بحرف كبير
        "type": userType,  // 2 للمعلمين، 1 للإدارة/محاسبين
        // joinDate: DateTime.now().toIso8601String(),  // أضفه إذا لزم الأمر
      };

      logger.i("SENDING EMPLOYEE DATA: ${jsonEncode(employeeData)}");
      await _handleRegistration(context: context, data: employeeData);
      if (mounted) setState(() => _isLoading = false);
    }

  }

  @override
  Widget build(BuildContext context) {
    return _BaseRegistrationScreen(
      formKey: _formKey,
      title: 'إنشاء حساب موظف',
      buttonText: "انشاء حساب موظف",
      isLoading: _isLoading,
      onButtonPressed: _registerEmployee,
      children: [
        _buildInputField("الإسم", "الإسم", controller: _nameController),
        _buildInputField("رقم الهاتف", "01xxxxxxxxx", isPhone: true, controller: _phoneController),
        _buildInputField("الرقم القومي", "14 رقم", controller: _ssnController),
        _buildDropdownField("المكتب التابع له", locationMap.keys.toList(), onChanged: (val) => _selectedLocation = val),
        _buildInputField("المؤهل الدراسي", "المؤهل", controller: _eduController),
        _buildInputField("البريد الإلكتروني", "example@staff.com", isRequired: true, controller: _emailController),
        _buildDropdownField("المسمى الوظيفي", jobTypeMap.keys.toList(),
            onChanged: (val) => setState(() => _selectedJobTitle = val)),
        _buildInputField("كلمة السر", "كلمة السر", isPassword: true, isObscured: _isPasswordObscured, onToggle: () => setState(() => _isPasswordObscured = !_isPasswordObscured), controller: _passwordController),
        _buildInputField("تأكيد كلمة السر", "تأكيد كلمة السر", isPassword: true, isObscured: _isConfirmObscured, onToggle: () => setState(() => _isConfirmObscured = !_isConfirmObscured), controller: _confirmPasswordController),
      ],
    );
  }
}

class _BaseRegistrationScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final GlobalKey<FormState> formKey;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool isLoading;

  _BaseRegistrationScreen({required this.title, required this.children, required this.formKey, required this.buttonText, required this.onButtonPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white, // ضمان ثبات اللون الأبيض
          scrolledUnderElevation: 0, // منع تغير اللون عند السكرول
          title: Text(title, style: TextStyle(color: darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: darkBlue), onPressed: () => Navigator.pop(context)),
        ),
        body: Form(
          key: formKey,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(children: [
                    ...children,
                    Spacer(),
                    Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 40.0),
                        child: isLoading
                            ? CircularProgressIndicator(color: primaryOrange)
                            : _buildPrimaryButton(context, buttonText, onButtonPressed)
                    )
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdownField(String label, List<String> items, {Function(String?)? onChanged}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Row(children: [
          Text(label, style: TextStyle(fontSize: 14, color: darkBlue, fontWeight: FontWeight.w600)),
          Text(' *', style: TextStyle(color: Colors.red))
        ]),
      ),
      DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
        decoration: _buildInputDecoration("اختيار $label"),
        validator: (value) => (value == null) ? "مطلوب" : null,
        onChanged: onChanged,
        items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
      ),
    ],
  );
}

Widget _buildInputField(String label, String hint, {bool isRequired = true, bool isPhone = false, bool isPassword = false, bool isObscured = false, VoidCallback? onToggle, TextEditingController? controller}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 8, top: 16), child: Row(children: [
        Text(label, style: TextStyle(fontSize: 14, color: darkBlue, fontWeight: FontWeight.w600)),
        if (isRequired) Text(' *', style: TextStyle(color: Colors.red))
      ])),
      TextFormField(
        controller: controller,
        obscureText: isPassword ? isObscured : false,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) return "مطلوب";
          if (label == "البريد الإلكتروني" && value != null && value.isNotEmpty) {
            if (!value.contains("@")) return "بريد غير صالح";
          }
          return null;
        },
        decoration: _buildInputDecoration(hint).copyWith(
          suffixIcon: isPassword ? IconButton(icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Color(0xFF9E9E9E)), onPressed: onToggle) : null,
        ),
      ),
    ],
  );
}

Widget _buildBirthdayRow({TextEditingController? dayCtrl, TextEditingController? monthCtrl, TextEditingController? yearCtrl}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Row(children: [
          Text("تاريخ الميلاد", style: TextStyle(fontSize: 14, color: darkBlue, fontWeight: FontWeight.w600)),
          Text(' *', style: TextStyle(color: Colors.red))
        ]),
      ),
      Row(children: [
        Expanded(child: _NumberInputField(hint: "يوم", controller: dayCtrl)),
        SizedBox(width: 10),
        Expanded(child: _NumberInputField(hint: "شهر", controller: monthCtrl)),
        SizedBox(width: 10),
        Expanded(child: _NumberInputField(hint: "سنة", controller: yearCtrl)),
      ]),
    ],
  );
}

class _NumberInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  _NumberInputField({required this.hint, this.controller});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textAlign: TextAlign.center,
    keyboardType: TextInputType.number,
    decoration: _buildInputDecoration(hint),
    validator: (value) => (value == null || value.isEmpty) ? "!" : null,
  );
}

InputDecoration _buildInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400)),
    errorStyle: TextStyle(fontSize: 12, height: 0.8),
  );
}

Widget _buildPrimaryButton(BuildContext context, String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(text, style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    ),
  );
}