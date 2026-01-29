import 'dart:convert';

List<SessionRecord> sessionRecordFromJson(String str) =>
    List<SessionRecord>.from(json.decode(str).map((x) => SessionRecord.fromJson(x)));

class SessionRecord {
  int? id;
  Level? level;
  Location? loc;
  List<GroupSession>? groupSessions;
  String? name;
  bool? active;

  SessionRecord({this.id, this.level, this.loc, this.groupSessions, this.name, this.active});

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
    id: json["id"],
    level: json["level"] == null ? null : Level.fromJson(json["level"]),
    loc: json["loc"] == null ? null : Location.fromJson(json["loc"]),
    groupSessions: json["groupSessions"] == null
        ? null
        : List<GroupSession>.from(json["groupSessions"].map((x) => GroupSession.fromJson(x))),
    name: json["name"],
    active: json["active"],
  );
}

class Level {
  String? name;
  factory Level.fromJson(Map<String, dynamic> json) => Level(name: json["name"]);
}

class Location {
  String? name;
  factory Location.fromJson(Map<String, dynamic> json) => Location(name: json["name"]);
}

class GroupSession {
  int? day;
  String? hour;

  GroupSession({this.day, this.hour});

  factory GroupSession.fromJson(Map<String, dynamic> json) => GroupSession(
    day: json["day"],
    hour: json["hour"],
  );

  // تحويل رقم اليوم لاسم اليوم (حسب السكرين شوت المرفقة 1=السبت)
  String get dayName {
    switch (day) {
      case 1: return "السبت";
      case 2: return "الأحد";
      case 3: return "الإثنين";
      case 4: return "الثلاثاء";
      case 5: return "الأربعاء";
      case 6: return "الخميس";
      case 7: return "الجمعة";
      default: return "";
    }
  }
}