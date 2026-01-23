import 'dart:convert';

ExamModel examModelFromJson(String str) => ExamModel.fromJson(json.decode(str));

class ExamModel {
  Data? data;
  dynamic statusCode;
  dynamic error;

  ExamModel({this.data, this.statusCode, this.error});

  factory ExamModel.fromJson(Map<String, dynamic> json) => ExamModel(
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
    statusCode: json["statusCode"],
    error: json["error"],
  );
}

class Data {
  Exam? exam;
  int? stId;
  int? examId;
  dynamic url;
  int? grade;
  String? note;

  Data({this.exam, this.stId, this.examId, this.url, this.grade, this.note});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    exam: json["exam"] == null ? null : Exam.fromJson(json["exam"]),
    stId: json["stId"],
    examId: json["examId"],
    url: json["url"],
    grade: json["grade"],
    note: json["note"],
  );
}

class Exam {
  int? id;
  String? name;
  String? description;
  int? levelId;

  Exam({this.id, this.name, this.description, this.levelId});

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    levelId: json["levelId"],
  );
}