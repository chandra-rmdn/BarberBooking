class ScheduleModel {
  final bool isOpen;
  final int openMinutes;
  final int closeMinutes;

  ScheduleModel({
    required this.isOpen,
    required this.openMinutes,
    required this.closeMinutes,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      isOpen: map["isOpen"] ?? false,
      openMinutes: map["openMinutes"] ?? 0,
      closeMinutes: map["closeMinutes"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isOpen": isOpen,
      "openMinutes": openMinutes,
      "closeMinutes": closeMinutes,
    };
  }
}
