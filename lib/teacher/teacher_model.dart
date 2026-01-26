import 'dart:convert';

TeacherModel teacherModelFromJson(String str) => TeacherModel.fromJson(json.decode(str));

class TeacherModel {
  TeacherData? data;
  dynamic statusCode;
  dynamic error;

  TeacherModel({this.data, this.statusCode, this.error});

  factory TeacherModel.fromJson(Map<String, dynamic> json) => TeacherModel(
    data: json["data"] == null ? null : TeacherData.fromJson(json["data"]),
    statusCode: json["statusCode"],
    error: json["error"],
  );
}

class TeacherData {
  int? id;
  DateTime? joinDate;
  Loc? loc;
  String? name;
  String? ssn;
  String? phone;
  String? educationDegree;
  List<dynamic>? courses; // الدورات التدريبية

  TeacherData({
    this.id,
    this.joinDate,
    this.loc,
    this.name,
    this.ssn,
    this.phone,
    this.educationDegree,
    this.courses,
  });

  factory TeacherData.fromJson(Map<String, dynamic> json) => TeacherData(
    id: json["id"],
    joinDate: json["joinDate"] == null ? null : DateTime.parse(json["joinDate"]),
    loc: json["loc"] == null ? null : Loc.fromJson(json["loc"]),
    name: json["name"],
    ssn: json["ssn"],
    phone: json["phone"],
    educationDegree: json["educationDegree"],
    courses: json["courses"] != null ? List<dynamic>.from(json["courses"]) : [],
  );
}

class Loc {
  int? id;
  String? name;
  String? address;

  Loc({this.id, this.name, this.address});

  factory Loc.fromJson(Map<String, dynamic> json) => Loc(
    id: json["id"],
    name: json["name"],
    address: json["address"],
  );
}