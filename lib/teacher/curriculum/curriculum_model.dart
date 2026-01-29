import 'dart:convert';

CurriculumResponse curriculumResponseFromJson(String str) => CurriculumResponse.fromJson(json.decode(str));

class CurriculumResponse {
  List<LevelData>? data;
  dynamic statusCode;
  dynamic error;

  CurriculumResponse({this.data, this.statusCode, this.error});

  factory CurriculumResponse.fromJson(Map<String, dynamic> json) => CurriculumResponse(
    data: json["data"] == null ? null : List<LevelData>.from(json["data"].map((x) => LevelData.fromJson(x))),
    statusCode: json["statusCode"],
    error: json["error"],
  );
}

class LevelData {
  int? id;
  String? name;
  bool? active;
  List<StudentCourse>? studentsCourses;

  LevelData({this.id, this.name, this.active, this.studentsCourses});

  factory LevelData.fromJson(Map<String, dynamic> json) => LevelData(
    id: json["id"],
    name: json["name"],
    active: json["active"],
    studentsCourses: json["studentsCourses"] == null
        ? null
        : List<StudentCourse>.from(json["studentsCourses"].map((x) => StudentCourse.fromJson(x))),
  );
}

class StudentCourse {
  String? name;
  String? description;
  int? levelId;
  String? url;
  dynamic file;
  bool? mandatory;
  int? typeId;

  StudentCourse({
    this.name,
    this.description,
    this.levelId,
    this.url,
    this.file,
    this.mandatory,
    this.typeId,
  });

  factory StudentCourse.fromJson(Map<String, dynamic> json) => StudentCourse(
    name: json["name"],
    description: json["description"],
    levelId: json["levelId"],
    url: json["url"],
    file: json["file"],
    mandatory: json["mandatory"],
    typeId: json["typeId"],
  );
}