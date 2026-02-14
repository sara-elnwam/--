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
  List<dynamic>? courses;

  TeacherData({this.id, this.joinDate, this.loc, this.name, this.ssn, this.phone, this.educationDegree, this.courses});

  factory TeacherData.fromJson(Map<String, dynamic> json) {
    return TeacherData(
      id: json["id"],
      // التعديل هنا: إذا كان التاريخ نل أو تاريخ افتراضي غير صحيح (0001)، يرجع تاريخ اليوم
      joinDate: (json["joinDate"] == null || json["joinDate"] == "0001-01-01T00:00:00")
          ? DateTime.now()
          : DateTime.parse(json["joinDate"]),
      loc: json["loc"] == null ? null : Loc.fromJson(json["loc"]),
      name: json["name"],
      ssn: json["ssn"],
      phone: json["phone"],
      educationDegree: json["educationDegree"],
      courses: json["courses"] == null ? [] : List<dynamic>.from(json["courses"]!.map((x) => x)),
    );
  }
}

class Loc {
  int? id;
  String? name;
  double? lat;
  double? lng;

  Loc({this.id, this.name, this.lat, this.lng});

  factory Loc.fromJson(Map<String, dynamic> json) => Loc(
    id: json["id"],
    name: json["name"],
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "id": id, "name": name, "lat": lat, "lng": lng,
  };
}