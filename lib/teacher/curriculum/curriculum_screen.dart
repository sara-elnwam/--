import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class CurriculumScreen extends StatelessWidget {
  final Color primaryBlue = const Color(0xFF1976D2);
  final Color darkBlue = const Color(0xFF2E3542);

  final List<Map<String, dynamic>> menuItems = [
    {'title': 'منهج (القرآن)', 'icon': Icons.menu_book_rounded, 'typeId': 3},
    {'title': 'اختبار', 'icon': Icons.assignment_turned_in_rounded, 'typeId': 5},
    {'title': 'السؤال الاسبوعي', 'icon': Icons.help_outline_rounded, 'typeId': 1},
    {'title': 'بحث', 'icon': Icons.search_rounded, 'typeId': 2},
    {'title': 'مقرر (مواد دينية)', 'icon': Icons.auto_stories_rounded, 'typeId': 4},
  ];

  @override
  Widget build(BuildContext context) {
    // تغليف الكود بـ Directionality لضمان ظهور التصميم بشكل صحيح من اليمين لليسار
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // إضافة AppBar لكي تظهر الشاشة بشكل احترافي مع زر رجوع تلقائي
        appBar: AppBar(
          title: const Text(
            "المنهج / المقرر",
            style: TextStyle(fontFamily: 'Almarai', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E3542),
        ),
        backgroundColor: const Color(0xFFF9FAFB), // لون خلفية مريح للعين
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                "دروس مصاحبة",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                  color: Color(0xFF2E3542),
                ),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) => _buildMenuCard(context, menuItems[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddCurriculumItemScreen(
              title: item['title'],
              typeId: item['typeId'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(item['icon'], color: primaryBlue, size: 30),
            ),
            const SizedBox(height: 12),
            Text(item['title'], style: const TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E3542))),
          ],
        ),
      ),
    );
  }
}

class AddCurriculumItemScreen extends StatefulWidget {
  final String title;
  final int typeId;
  const AddCurriculumItemScreen({super.key, required this.title, required this.typeId});

  @override
  _AddCurriculumItemScreenState createState() => _AddCurriculumItemScreenState();
}

class _AddCurriculumItemScreenState extends State<AddCurriculumItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String? _fileName = "لم يتم اختيار ملف";
  String? _filePath;
  bool _isMandatory = false;
  bool _isUploading = false;
  String? _selectedLevelValue;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        _filePath = result.files.single.path;
      });
    }
  }





  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _filePath == null || _selectedLevelValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("برجاء إكمال البيانات")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. تغيير الرابط إلى Save وتغيير النوع إلى POST
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://nour-al-eman.runasp.net/api/StudentCources/Save'),
      );

      // 2. تعبئة الحقول (تأكدي من مطابقة الأحرف الكبيرة والصغيرة حسب السيرفر)
      request.fields['Name'] = _nameController.text;
      request.fields['Description'] = _descController.text;

      int levelId = 1;
      if (_selectedLevelValue == "المستوى الثاني") levelId = 2;
      else if (_selectedLevelValue == "المستوى الثالث") levelId = 3;
      else if (_selectedLevelValue == "المستوى الرابع") levelId = 4;

      request.fields['LevelId'] = levelId.toString();
      request.fields['TypeId'] = widget.typeId.toString();
      request.fields['Mandatory'] = _isMandatory.toString();

      // 3. إضافة الملف - تأكدي من اسم الحقل 'file' أو 'File' حسب متطلبات السيرفر
      request.files.add(await http.MultipartFile.fromPath('file', _filePath!));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📡 كود الاستجابة: ${response.statusCode}");
      print("📥 رد السيرفر: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت الإضافة بنجاح ✅")));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("خطأ ${response.statusCode}: يرجى التحقق من صحة البيانات المرسلة"))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ اتصال: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: Text(widget.title, style: const TextStyle(color: Color(0xFF2E3542), fontFamily: 'Almarai', fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("الاسم*"),
              _buildTextField(_nameController, "ادخل اسم ${widget.title}"),
              const SizedBox(height: 20),
              _buildLabel("التفاصيل*"),
              _buildTextField(_descController, "ادخل تفاصيل ${widget.title}", maxLines: 3),
              const SizedBox(height: 20),
              _buildLabel("المستويات*"),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel("الملف*"),
              _buildFilePicker(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isMandatory,
                    onChanged: (val) => setState(() => _isMandatory = val!),
                    activeColor: const Color(0xFF1976D2),
                  ),
                  const Text("اجباري", style: TextStyle(fontFamily: 'Almarai')),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC66422),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isUploading ? null : _submitData,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("إضافة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Almarai')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14, fontFamily: 'Almarai')),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) => TextField(
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      contentPadding: const EdgeInsets.all(12),
    ),
  );

  Widget _buildDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedLevelValue,
        hint: const Text("اختار المستويات", style: TextStyle(fontSize: 14, fontFamily: 'Almarai')),
        items: ["المستوى الاول", "المستوى الثاني", "المستوى الثالث", "المستوى الرابع"].map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (val) => setState(() => _selectedLevelValue = val),
      ),
    ),
  );

  Widget _buildFilePicker() => Container(
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
    child: Row(
      children: [
        IconButton(icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blue), onPressed: _pickFile),
        Expanded(child: Text(_fileName!, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
        Container(
          margin: const EdgeInsets.all(5),
          child: TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.grey.shade100),
            onPressed: _pickFile,
            child: const Text("Choose File", style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}