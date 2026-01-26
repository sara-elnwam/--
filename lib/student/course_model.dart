import 'dart:convert';

CourseModel courseModelFromJson(String str) => CourseModel.fromJson(json.decode(str));

class CourseModel {
  List<Course>? data;
  dynamic statusCode;
  dynamic error;

  CourseModel({this.data, this.statusCode, this.error});

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    data: json["data"] == null ? null : List<Course>.from(json["data"].map((x) => Course.fromJson(x))),
    statusCode: json["statusCode"],
    error: json["error"],
  );
}

class Course {
  int? id;
  String? name;
  String? description;
  int? levelId;
  String? url;
  int? typeId;

  Course({this.id, this.name, this.description, this.levelId, this.url, this.typeId});

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    levelId: json["levelId"],
    url: json["url"],
    typeId: json["typeId"],
  );
}