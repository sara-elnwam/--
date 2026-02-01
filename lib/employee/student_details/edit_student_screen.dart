import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// استيراد تعريفات الألوان من ملف اللوجين لضمان التطابق
final Color primaryOrange = Color(0xFFC66422);
final Color darkBlue = Color(0xFF2E3542);
final Color greyText = Color(0xFF707070);

class EditStudentScreen extends StatefulWidget {
  final int studentId;
  final Map<String, dynamic>? initialData;

  const EditStudentScreen({super.key, required this.studentId, this.initialData});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  // الـ Controllers فارغة تماماً لربطها بالداتا الحقيقية
  late TextEditingController nameController;
  late TextEditingController fatherJobController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController phone2Controller; // الحقل الناقص من الصور
  late TextEditingController schoolController;

  DateTime? birthDate;
  DateTime? joinDate;

  String? selectedBranch;
  String? studentStatus;
  String? notebookType;
  String? paymentMethod;
  String? attendanceType;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تهيئة الـ Controllers (تكون فارغة إلا لو تم تمرير داتا حقيقية)
    nameController = TextEditingController(text: widget.initialData?['name']?.toString() ?? '');
    fatherJobController = TextEditingController(text: widget.initialData?['fatherJob']?.toString() ?? '');
    addressController = TextEditingController(text: widget.initialData?['address']?.toString() ?? '');
    phoneController = TextEditingController(text: widget.initialData?['phone']?.toString() ?? '');
    phone2Controller = TextEditingController(text: widget.initialData?['phone2']?.toString() ?? '');
    schoolController = TextEditingController(text: widget.initialData?['governmentSchool']?.toString() ?? '');

    // ربط القوائم بالبيانات الحقيقية
    selectedBranch = widget.initialData?['branch'];
    studentStatus = widget.initialData?['status'];
    notebookType = widget.initialData?['notebook'];
    paymentMethod = widget.initialData?['payment'];
    attendanceType = widget.initialData?['attendance'];
  }

  // استخدام نفس تصميم الحقول من شاشة اللوجين
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300)
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400) // نفس لون فوكس اللوجين
      ),
      errorStyle: TextStyle(fontSize: 12, height: 0.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white, // خلفية بيضاء سادة
        appBar: AppBar(
          backgroundColor: Colors.white, // AppBar أبيض عادي
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text("تعديل بيانات الطالب",
              style: TextStyle(color: darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: darkBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSimpleLabel("الإسم", isRequired: true),
                TextFormField(controller: nameController, decoration: _buildInputDecoration("اسم الطالب")),
                const SizedBox(height: 18),

                _buildSimpleLabel("وظيفة الأب"),
                TextFormField(controller: fatherJobController, decoration: _buildInputDecoration("وظيفة الأب")),
                const SizedBox(height: 18),

                _buildSimpleLabel("العنوان", isRequired: true),
                TextFormField(controller: addressController, decoration: _buildInputDecoration("العنوان بالتفصيل")),
                const SizedBox(height: 18),

                _buildSimpleLabel("المكتب التابع له", isRequired: true),
                DropdownButtonFormField<String>(
                  value: selectedBranch,
                  decoration: _buildInputDecoration("اختر المكتب"),
                  items: ["مدرسة نور الإيمان", "rouby's location", "مسجد الشيخ ابراهيم", "مسجد العباسي", "مكتب الموقف"]
                      .map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => selectedBranch = val),
                ),
                const SizedBox(height: 18),

                _buildSimpleLabel("تاريخ الميلاد", isRequired: true),
                _buildDateBox(birthDate, (date) => setState(() => birthDate = date)),
                const SizedBox(height: 18),

                _buildSimpleLabel("تاريخ الانضمام للمدرسة", isRequired: true),
                _buildDateBox(joinDate, (date) => setState(() => joinDate = date)),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSimpleLabel("حالة الطالب", isRequired: true),
                          DropdownButtonFormField<String>(
                            value: studentStatus,
                            decoration: _buildInputDecoration("اختر الحالة"),
                            items: ["يتيم", "ثانوي", "عادي"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => studentStatus = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSimpleLabel("الكراسة", isRequired: true),
                          DropdownButtonFormField<String>(
                            value: notebookType,
                            decoration: _buildInputDecoration("اختر النوع"),
                            items: ["مجاني", "مدفوع"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => notebookType = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                _buildSimpleLabel("طريقة الدفع", isRequired: true),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: _buildInputDecoration("اختر طريقة الدفع"),
                  items: ["مجاني", "شهري", "6 شهور"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => paymentMethod = val),
                ),
                const SizedBox(height: 18),

                _buildSimpleLabel("الرقم هاتف ولي الامر (1)", isRequired: true),
                TextFormField(controller: phoneController, keyboardType: TextInputType.phone, decoration: _buildInputDecoration("01xxxxxxxxx")),
                const SizedBox(height: 18),

                _buildSimpleLabel("الرقم هاتف ولي الامر (2)"),
                TextFormField(controller: phone2Controller, keyboardType: TextInputType.phone, decoration: _buildInputDecoration("اختياري")),
                const SizedBox(height: 18),

                _buildSimpleLabel("اسم المدرسة الحكومية", isRequired: true),
                TextFormField(controller: schoolController, decoration: _buildInputDecoration("المدرسة")),
                const SizedBox(height: 18),

                _buildSimpleLabel("الحضور", isRequired: true),
                DropdownButtonFormField<String>(
                  value: attendanceType,
                  decoration: _buildInputDecoration("اختر الحضور"),
                  items: ["اونلاين", "اوفلاين"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => attendanceType = val),
                ),
                const SizedBox(height: 40),

                // زر الحفظ بتصميم اللوجين
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('حفـــــظ التعديلات', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت العناوين بنفس تنسيق اللوجين بالضبط
  Widget _buildSimpleLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(children: [
        Text(text, style: TextStyle(fontSize: 14, color: darkBlue, fontWeight: FontWeight.w600)),
        if (isRequired) Text(' *', style: TextStyle(color: Colors.red))
      ]),
    );
  }

  // ويدجت اختيار التاريخ بتصميم متناسق
  Widget _buildDateBox(DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? "اختيار التاريخ" : DateFormat('yyyy/MM/dd').format(date),
                style: TextStyle(color: date == null ? Colors.grey.shade400 : darkBlue)),
            Icon(Icons.calendar_today, color: primaryOrange, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // هنا يتم الربط بالـ API لاحقاً
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    }
  }
}