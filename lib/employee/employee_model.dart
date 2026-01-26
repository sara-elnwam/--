import 'dart:convert';

EmployeeModel employeeModelFromJson(String str) => EmployeeModel.fromJson(json.decode(str));

class EmployeeModel {
  EmployeeData? data;
  dynamic statusCode;
  dynamic error;

  EmployeeModel({this.data, this.statusCode, this.error});

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
    data: json["data"] == null ? null : EmployeeData.fromJson(json["data"]),
    statusCode: json["statusCode"],
    error: json["error"],
  );
}

class EmployeeData {
  int? id;
  DateTime? joinDate;
  Loc? loc;
  String? name;
  String? ssn;
  String? phone;
  String? educationDegree;

  EmployeeData({
    this.id,
    this.joinDate,
    this.loc,
    this.name,
    this.ssn,
    this.phone,
    this.educationDegree,
  });

  factory EmployeeData.fromJson(Map<String, dynamic> json) => EmployeeData(
    id: json["id"],
    joinDate: json["joinDate"] == null ? null : DateTime.parse(json["joinDate"]),
    loc: json["loc"] == null ? null : Loc.fromJson(json["loc"]),
    name: json["name"],
    ssn: json["ssn"],
    phone: json["phone"],
    educationDegree: json["educationDegree"],
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