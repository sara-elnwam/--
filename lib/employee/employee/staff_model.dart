import 'dart:convert';

List<StaffModel> staffFromJson(String str) {
  final jsonData = json.decode(str);
  return List<StaffModel>.from(jsonData.map((x) => StaffModel.fromJson(x)));
}

class StaffModel {
  int? id;
  DateTime? joinDate;
  StaffLoc? loc;
  StaffType? employeeType;
  String? name;
  String? ssn;
  String? phone;
  String? educationDegree;
  int? locId;

  StaffModel({
    this.id,
    this.joinDate,
    this.loc,
    this.employeeType,
    this.name,
    this.ssn,
    this.phone,
    this.educationDegree,
    this.locId,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
    id: json["id"],
    joinDate: json["joinDate"] == null || json["joinDate"] == "0001-01-01T00:00:00"
        ? null : DateTime.parse(json["joinDate"]),
    loc: json["loc"] == null ? null : StaffLoc.fromJson(json["loc"]),
    employeeType: json["employeeType"] == null ? null : StaffType.fromJson(json["employeeType"]),
    name: json["name"] ?? "اسم غير معروف",
    ssn: json["ssn"] ?? "",
    phone: json["phone"] ?? "---",
    educationDegree: json["educationDegree"] ?? "",
    locId: json["locId"],
  );
}

class StaffLoc {
  int? id;
  String? name;
  String? address;

  StaffLoc({this.id, this.name, this.address});

  factory StaffLoc.fromJson(Map<String, dynamic> json) => StaffLoc(
    id: json["id"],
    name: json["name"],
    address: json["address"],
  );
}

class StaffType {
  int? id;
  String? name;

  StaffType({this.id, this.name});

  factory StaffType.fromJson(Map<String, dynamic> json) => StaffType(
    id: json["id"],
    name: json["name"],
  );
}