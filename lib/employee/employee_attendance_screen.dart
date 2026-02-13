import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// تعريف الألوان الخاصة بنظام الموظف لضمان التناسق
final Color darkBlue = Color(0xFF2E3542);
const Color kActiveBlue = Color(0xFF1976D2);
const Color kLabelGrey = Color(0xFF718096);
const Color kBorderColor = Color(0xFFE2E8F0);

class EmployeeAttendanceScreen extends StatefulWidget {
  @override
  _EmployeeAttendanceScreenState createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  String _currentLocationText = "جاري تحديد موقعك...";
  String _currentTime = "";
  String _checkType = "In";
  late Timer _timer;

  Position? _myPosition;
  bool _attendanceDone = false;

  Map<String, dynamic>? _selectedOffice;
  String? _selectedLocationName;
  bool _isInRange = false;
  bool _isLoadingStatus = true;
  bool _isLoading = false;
  List<dynamic> _apiOffices = [];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    _initLocation();
    _fetchOffices();
    _checkCurrentStatus();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = intl.DateFormat('hh:mm a').format(now)
        .replaceFirst('AM', 'ص').replaceFirst('PM', 'م');
    if (mounted) setState(() => _currentTime = formattedTime);
  }

  bool _isPointInPolygon(Position userPos, List<Map<String, double>> polygonCoords) {
    if (polygonCoords.isEmpty) return false;
    int i, j = polygonCoords.length - 1;
    bool oddNodes = false;
    double x = userPos.latitude;
    double y = userPos.longitude;

    for (i = 0; i < polygonCoords.length; i++) {
      double xi = polygonCoords[i]['lat']!;
      double yi = polygonCoords[i]['lng']!;
      double xj = polygonCoords[j]['lat']!;
      double yj = polygonCoords[j]['lng']!;

      if ((yi < y && yj >= y || yj < y && yi >= y) &&
          (xi + (y - yi) / (yj - yi) * (xj - xi) < x)) {
        oddNodes = !oddNodes;
      }
      j = i;
    }
    return oddNodes;
  }

  Future<void> _fetchOffices() async {
    try {
      // الرابط الصحيح كما في صورة الـ Swagger
      final response = await http.get(Uri.parse('https://nour-al-eman.runasp.net/api/Locations/Getall'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // نأخذ القائمة من السيرفر.
          // إذا كان السيرفر يرسلها داخل 'data' نأخذها، وإلا نأخذ الاستجابة مباشرة.
          _apiOffices = data['data'] ?? data;
        });

        if (_apiOffices.isEmpty) {
          _showSnackBar("قائمة المكاتب فارغة في السيرفر", Colors.orange);
        }
      } else {
        _showSnackBar("خطأ في جلب البيانات: ${response.statusCode}", Colors.red);
      }
    } catch (e) {
      print("Network Error: $e");
      _showSnackBar("تعذر الاتصال بالسيرفر، تأكد من الإنترنت", Colors.red);
    }
  }

  Future<void> _checkCurrentStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String empId = prefs.getString('user_id') ?? "";
      final url = 'https://nour-al-eman.runasp.net/api/Locations/GetAllEmployeeAttendanceById?EmpId=$empId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> logs = data['data'] ?? [];
        if (logs.isNotEmpty) {
          var lastLog = logs.first;
          String todayDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
          if (lastLog['date'].contains(todayDate)) {
            if (lastLog['checkOutTime'] == null || lastLog['checkOutTime'] == "--") {
              setState(() {
                _checkType = "Out";
                _attendanceDone = true;
                _selectedLocationName = lastLog['locationName'];
                _isInRange = true;
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error checking status: $e");
    } finally {
      setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _myPosition = position;
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted && placemarks.isNotEmpty) {
        setState(() {
          _currentLocationText = "${placemarks[0].locality ?? ''} - ${placemarks[0].administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocationText = "تعذر تحديد الموقع");
    }
  }

  void _checkDistance(Map<String, dynamic> office) {
    if (_myPosition == null) {
      _showSnackBar("جاري تحديد موقعك، حاول مرة أخرى خلال ثوانٍ", Colors.orange);
      return;
    }

    // تنظيف النص القادم من السيرفر وتحويله لنقاط
    String rawCoords = office['coordinates'] ?? "";

    // استبدال الفواصل بـ ; لتوحيد الشكل وتقسيمها
    rawCoords = rawCoords.replaceAll(',', ';');
    List<String> parts = rawCoords.split(';').where((s) => s.trim().isNotEmpty).toList();

    List<Map<String, double>> polygonPoints = [];

    for (int i = 0; i < parts.length; i += 2) {
      if (i + 1 < parts.length) {
        double? lat = double.tryParse(parts[i].trim());
        double? lng = double.tryParse(parts[i+1].trim());
        if (lat != null && lng != null) {
          polygonPoints.add({'lat': lat, 'lng': lng});
        }
      }
    }

    setState(() {
      _selectedOffice = office;
      _selectedLocationName = office['name'];

      if (polygonPoints.length >= 3) {
        // إذا كانت 3 نقاط أو أكثر نتعامل كمضلع (Polygon)
        _isInRange = _isPointInPolygon(_myPosition!, polygonPoints);
      }
      else if (polygonPoints.isNotEmpty) {
        // إذا كانت نقطة واحدة (أو نقطتين) نتعامل كدائرة قطرها 500 متر حول أول نقطة
        double dist = Geolocator.distanceBetween(
            _myPosition!.latitude, _myPosition!.longitude,
            polygonPoints[0]['lat']!, polygonPoints[0]['lng']!
        );
        _isInRange = dist <= 500; // يمكنك تغيير المسافة من هنا
      } else {
        _isInRange = false;
      }
    });

    if (!_isInRange) {
      _showSnackBar("أنت خارج النطاق لـ ${_selectedLocationName}", Colors.red);
    } else {
      _showSnackBar("أنت داخل نطاق ${_selectedLocationName}", Colors.green);
    }
  }
  Future<void> _startBiometricAuth() async {
    if (!_isInRange) {
      _showSnackBar("لا يمكنك البصم لأنك خارج النطاق", Colors.red);
      return;
    }

    try {
      final bool canAuth = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuth) {
        _showSnackBar("البصمة غير مدعومة على هذا الجهاز", Colors.red);
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'تأكيد الحضور في $_selectedLocationName',
      );

      if (authenticated) {
        await _sendAttendanceToServer();
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء التوثيق", Colors.red);    }
  }

  Future<void> _sendAttendanceToServer() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? rawId = prefs.getString('user_id');

      if (rawId == null || rawId == "0") {
        _showSnackBar("خطأ: كود المستخدم غير صالح", Colors.red);
        return;
      }

      // تجهيز البيانات بالصيغة التي طلبها السيرفر في آخر Error Log
      final Map<String, dynamic> attendanceData = {
        "UserId": rawId.toString(), // إرسال المعرف كنص "5"
        "userLocation": _selectedOffice?['id'], // إرسال المعرف كرقم (int)
        "CheckType": _checkType,
        "HisCoordinate": { // إرسال الإحداثيات كـ Object وليس String
          "lat": _myPosition?.latitude,
          "lng": _myPosition?.longitude,
        },
        "Date": DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('https://nour-al-eman.runasp.net/api/Locations/employee-attendance'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(attendanceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("تم تسجيل ${_checkType == "In" ? "الحضور" : "الانصراف"} بنجاح", Colors.green);
        setState(() {
          if (_checkType == "In") {
            _attendanceDone = true;
            _checkType = "Out";
          } else {
            _attendanceDone = false;
            _checkType = "In";
          }
        });
      } else {
        // لعرض السبب في حالة وجود خطأ آخر
        print("Response: ${response.body}");
        _showSnackBar("فشل التسجيل: تأكد من البيانات", Colors.red);
      }
    } catch (e) {
      _showSnackBar("حدث خطأ تقني: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontFamily: 'Almarai')),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            title: Text("  ", style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true
        ),
        body: _isLoadingStatus
            ? const Center(child: CircularProgressIndicator(color: kActiveBlue))
            : RefreshIndicator(
          onRefresh: () async {
            await _initLocation();
            await _fetchOffices();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Column(
                    children: [
                      _buildMiniRow(Icons.location_on, _currentLocationText),
                      const Divider(height: 25, color: kBorderColor),
                      _buildMiniRow(Icons.access_time_filled, "ساعات العمل: 00:00 ص - 00:00 م"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernDropdown(),
                const SizedBox(height: 40),
                Text(_currentTime, style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: darkBlue, fontFamily: 'Almarai')),
                const SizedBox(height: 40),
                _buildFingerprintButton(),
                const SizedBox(height: 20),
                if (_isLoading) const Padding(padding: EdgeInsets.only(top: 15), child: CircularProgressIndicator(color: kActiveBlue))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: kActiveBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: darkBlue, fontFamily: 'Almarai'))),
      ],
    );
  }

  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(" اختيار المكتب /الموقع", style: TextStyle(fontSize: 13, color: kLabelGrey, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _selectedOffice != null ? kActiveBlue : kBorderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedOffice,
              hint: const Text("اختر مكان تواجدك الحالي", style: TextStyle(fontFamily: 'Almarai')),
              items: _apiOffices.map((office) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: office,
                  child: Text(office['name'] ?? "", style: const TextStyle(fontFamily: 'Almarai')),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _checkDistance(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFingerprintButton() {
    bool canPress = _selectedOffice != null && _isInRange;
    String statusText = _checkType == "In" ? "اضغط لتسجيل الحضور" : "اضغط لتسجيل الانصراف";
// ابحثي عن هذا السطر في _buildFingerprintButton
    // استبدلي السطر القديم بهذا السطر
    Color activeColor = _checkType == "In" ? kActiveBlue : Colors.red;
    return Column(
      children: [
        GestureDetector(
          onTap: canPress ? _startBiometricAuth : () {
            if (_selectedOffice == null) {
              _showSnackBar("برجاء اختيار المكتب أولاً", Colors.orange);
            } else if (!_isInRange) {
              _showSnackBar("أنت خارج النطاق، لا يمكنك البصم", Colors.red);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                  color: canPress ? activeColor : Colors.grey.shade300,
                  width: 5
              ),
              boxShadow: [
                if (canPress) BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Icon(
              _checkType == "In" ? Icons.fingerprint : Icons.exit_to_app,
              size: 80,
              color: canPress ? activeColor : Colors.grey.shade300,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          statusText,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: canPress ? activeColor : Colors.grey,
              fontFamily: 'Almarai'
          ),
        ),
      ],
    );
  }
}