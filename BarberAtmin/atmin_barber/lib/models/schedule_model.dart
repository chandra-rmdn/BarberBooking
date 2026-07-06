class ScheduleModel {
  final bool isOpen;
  final int openMinutes;
  final int closeMinutes;
  final String name;
  final String reason;
  final String type;

  ScheduleModel({
    required this.isOpen,
    required this.openMinutes,
    required this.closeMinutes,
    required this.name,
    required this.reason,
    required this.type,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      isOpen: map["isOpen"] ?? false,
      openMinutes: map["openMinutes"] ?? 0,
      closeMinutes: map["closeMinutes"] ?? 0,
      name: map["name"] ?? "",
      reason: map["reason"] ?? "",
      type: map["type"] ?? "custom",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isOpen": isOpen,
      "openMinutes": openMinutes,
      "closeMinutes": closeMinutes,
      "name": name,
      "reason": reason,
      "type": type,
    };
  }
}
