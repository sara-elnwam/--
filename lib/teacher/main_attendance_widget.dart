import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart' as intl;

class MainAttendanceScreen extends StatefulWidget {
  @override
  _MainAttendanceScreenState createState() => _MainAttendanceScreenState();
}

class _MainAttendanceScreenState extends State<MainAttendanceScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  String _currentLocationText = "جاري تحديد موقعك...";
  String _currentTime = "";
  late Timer _timer;

  Position? _myPosition;
  bool _attendanceDone = false;
  String? _selectedLocation;

  // القائمة الكاملة للمكاتب كما طلبتِ
  final Map<String, String> _officesList = {
    "مدرسة نور الإيمان": "30.384365;30.352138",
    "rouby's location": "30.381908;30.354219",
    "مسجد الشيخ ابراهيم": "30.382301;30.349434",
    "مسجد العباسي": "30.380126;30.351612",
    "مسجد الهدى والنور": "30.381000;30.350000",
    "مضيفة نافع": "30.381500;30.351000",
    "مكتب الموقف": "30.382000;30.352500",
  };

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) => _updateTime());
    _initLocation();
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
        Placemark place = placemarks[0];
        setState(() {
          _currentLocationText = "${place.locality ?? ''} - ${place.administrativeArea ?? ''} - ${place.country ?? ''}"
              .replaceAll(RegExp(r'\d+\+?\w+'), '')
              .trim();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocationText = "تعذر تحديد الموقع");
    }
  }

  Future<void> _startBiometricAuth() async {
    if (_selectedLocation == null) {
      _showSnackBar("يرجى اختيار المكتب أولاً", Colors.orange);
      return;
    }
    try {
      bool canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        bool authenticated = await auth.authenticate(
          localizedReason: 'تأكيد الحضور في $_selectedLocation',
        );
        if (authenticated) _verifyLocationAndFinish();
      } else {
        _showSnackBar("البصمة غير مدعومة", Colors.red);
      }
    } catch (e) {
      _showSnackBar("حدث خطأ في التحقق", Colors.red);
    }
  }

  Future<void> _verifyLocationAndFinish() async {
    String? coordsString = _officesList[_selectedLocation];
    if (coordsString != null && _myPosition != null) {
      List<String> parts = coordsString.split(';');
      double lat = double.parse(parts[0]);
      double lon = double.parse(parts[1]);

      double distance = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, lat, lon);
      if (distance < 500) {
        setState(() => _attendanceDone = true);
        _showSnackBar("تم تسجيل الدخول بنجاح ✅", Colors.green);
      } else {
        _showSnackBar("أنت خارج نطاق الموقع ", Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(" ", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // كارت المعلومات العلوي (تم رفعه وتصغيره)
              Container(
                margin: EdgeInsets.only(top: 1),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    _buildMiniRow(Icons.location_on, _currentLocationText),
                    Divider(height: 20),
                    _buildMiniRow(Icons.access_time_filled, "ساعات العمل: 00:00 ص - 00:00 م"),
                  ],
                ),
              ),
              SizedBox(height: 25),
              // القائمة المنسدلة
              _buildModernDropdown(),
              SizedBox(height: 40),
              // الساعة
              Text(_currentTime, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: Color(0xFF1A237E))),
              SizedBox(height: 50),
              // زر البصمة
              _buildFingerprintButton(),
              SizedBox(height: 15),
              Text(
                _attendanceDone ? "تم الحضور" : "تسجيل الدخول",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _attendanceDone ? Colors.green : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF1A237E), size: 20),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87))),
      ],
    );
  }

  Widget _buildModernDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(" المكتب / الموقع", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLocation,
              dropdownColor: Colors.white, // القائمة بيضاء
              hint: Text("اختار المكتب/الموقع", style: TextStyle(fontSize: 14)),
              items: _officesList.keys.map((name) => DropdownMenuItem(
                value: name,
                child: Text(name, style: TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) => setState(() { _selectedLocation = val; _attendanceDone = false; }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFingerprintButton() {
    Color color = _attendanceDone ? Colors.green : (_selectedLocation != null ? Color(0xFF1A237E) : Colors.grey[200]!);
    return GestureDetector(
      onTap: _attendanceDone ? null : _startBiometricAuth,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, spreadRadius: 5)],
          border: Border.all(color: color.withOpacity(0.1), width: 8),
        ),
        child: Icon(_attendanceDone ? Icons.check_circle : Icons.fingerprint, size: 70, color: color),
      ),
    );
  }
}
