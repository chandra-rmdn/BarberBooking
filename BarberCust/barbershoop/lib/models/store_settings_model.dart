class StoreSettingsModel {
  final int bookingBufferMinutes;

  final int slotDurationMinutes;

  final int maxBookingDays;

  StoreSettingsModel({
    required this.bookingBufferMinutes,
    required this.slotDurationMinutes,
    required this.maxBookingDays,
  });

  factory StoreSettingsModel.fromMap(Map<String, dynamic> map) {
    return StoreSettingsModel(
      bookingBufferMinutes: map["bookingBufferMinutes"] ?? 30,
      slotDurationMinutes: map["slotDurationMinutes"] ?? 30,
      maxBookingDays: map["maxBookingDays"] ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "bookingBufferMinutes": bookingBufferMinutes,

      "slotDurationMinutes": slotDurationMinutes,

      "maxBookingDays": maxBookingDays,
    };
  }
}
