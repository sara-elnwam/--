// To parse this JSON data, do
//
//     final taskModel = taskModelFromJson(jsonString);

import 'dart:convert';

TaskModel taskModelFromJson(String str) => TaskModel.fromJson(json.decode(str));

String taskModelToJson(TaskModel data) => json.encode(data.toJson());

class TaskModel {
  List<Datum>? data;
  dynamic statusCode;
  dynamic error;

  TaskModel({
    this.data,
    this.statusCode,
    this.error,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    data: json["data"] == null ? [] : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    statusCode: json["statusCode"],
    error: json["error"],
  );

  Map<String, dynamic> toJson() => {
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "statusCode": statusCode,
    "error": error,
  };
}

class Datum {
  int? id;
  dynamic level;
  dynamic type;
  List<StudentExam>? studentExams;
  String? name;
  String? description;
  int? levelId;
  String? url;
  dynamic file;
  bool? mandatory;
  int? typeId;

  Datum({
    this.id,
    this.level,
    this.type,
    this.studentExams,
    this.name,
    this.description,
    this.levelId,
    this.url,
    this.file,
    this.mandatory,
    this.typeId,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    id: json["id"],
    level: json["level"],
    type: json["type"],
    studentExams: json["studentExams"] == null ? [] : List<StudentExam>.from(json["studentExams"]!.map((x) => StudentExam.fromJson(x))),
    name: json["name"],
    description: json["description"],
    levelId: json["levelId"],
    url: json["url"],
    file: json["file"],
    mandatory: json["mandatory"],
    typeId: json["typeId"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "level": level,
    "type": type,
    "studentExams": studentExams == null ? [] : List<dynamic>.from(studentExams!.map((x) => x.toJson())),
    "name": name,
    "description": description,
    "levelId": levelId,
    "url": url,
    "file": file,
    "mandatory": mandatory,
    "typeId": typeId,
  };
}

class StudentExam {
  int? stId;
  int? examId;
  dynamic url;
  int? grade;
  String? note;

  StudentExam({
    this.stId,
    this.examId,
    this.url,
    this.grade,
    this.note,
  });

  factory StudentExam.fromJson(Map<String, dynamic> json) => StudentExam(
    stId: json["stId"],
    examId: json["examId"],
    url: json["url"],
    grade: json["grade"],
    note: json["note"],
  );

  Map<String, dynamic> toJson() => {
    "stId": stId,
    "examId": examId,
    "url": url,
    "grade": grade,
    "note": note,
  };
}
