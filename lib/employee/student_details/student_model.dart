import 'dart:convert';

// دالة لتحويل النص القادم من السيرفر إلى قائمة طلاب
// دالة لمعالجة القائمة القادمة من السيرفر
List<StudentModel> studentsFromJson(String str) {
  final jsonData = json.decode(str);
  // السيرفر يرسل البيانات مباشرة كـ List بناءً على الصور
  return List<StudentModel>.from(jsonData.map((x) => StudentModel.fromJson(x)));
}

class StudentModel {
  int? id;
  DateTime? joinDate;
  String? studentType; // نوع الطالب (مثلاً: صورة، عادي)
  String? paymentType; // طريقة الدفع
  String? documentType;
  String? typeInfamily;
  Loc? loc;
  String? name;
  String? phone;
  String? address;
  String? parentJob;
  String? governmentSchool;
  String? attendanceType;
  DateTime? birthDate;
  int? locId;
  String? phone2;
  int? groupId;
  int? levelId;

  StudentModel({
    this.id,
    this.joinDate,
    this.paymentType,
    this.documentType,
    this.typeInfamily,
    this.loc,
    this.name,
    this.phone,
    this.address,
    this.parentJob,
    this.governmentSchool,
    this.attendanceType,
    this.birthDate,
    this.locId,
    this.phone2,
    this.groupId,
    this.levelId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
    id: json["id"],
    joinDate: json["joinDate"] == null ? null : DateTime.parse(json["joinDate"]),
    paymentType: json["paymentType"],
    documentType: json["documentType"],
    typeInfamily: json["typeInfamily"],
    loc: json["loc"] == null ? null : Loc.fromJson(json["loc"]),
    name: json["name"] ?? "اسم غير معروف",
    phone: json["phone"] ?? "---",
    address: json["address"],
    parentJob: json["parentJob"],
    governmentSchool: json["governmentSchool"],
    attendanceType: json["attendanceType"],
    birthDate: json["birthDate"] == null ? null : DateTime.parse(json["birthDate"]),
    locId: json["locId"],
    phone2: json["phone2"],
    groupId: json["groupId"],
    levelId: json["levelId"],
  );
}

class Loc {
  int? id;
  String? name;
  String? address;
  String? coordinates;
  bool? status;

  Loc({this.id, this.name, this.address, this.coordinates, this.status});

  factory Loc.fromJson(Map<String, dynamic> json) => Loc(
    id: json["id"],
    name: json["name"],
    address: json["address"],
    coordinates: json["coordinates"],
    status: json["status"],
  );
}