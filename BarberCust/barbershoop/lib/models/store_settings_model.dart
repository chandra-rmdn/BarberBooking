class StoreSettingsModel {
  final bool isStoreOpen;

  final int bookingBufferMinutes;

  final int slotDurationMinutes;

  final int maxBookingDays;

  StoreSettingsModel({
    required this.isStoreOpen,
    required this.bookingBufferMinutes,
    required this.slotDurationMinutes,
    required this.maxBookingDays,
  });

  factory StoreSettingsModel.fromMap(Map<String, dynamic> map) {
    return StoreSettingsModel(
      isStoreOpen: map["isStoreOpen"] ?? true,
      bookingBufferMinutes: map["bookingBufferMinutes"] ?? 30,
      slotDurationMinutes: map["slotDurationMinutes"] ?? 30,
      maxBookingDays: map["maxBookingDays"] ?? 7,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isStoreOpen": isStoreOpen,
      
      "bookingBufferMinutes": bookingBufferMinutes,

      "slotDurationMinutes": slotDurationMinutes,

      "maxBookingDays": maxBookingDays,
    };
  }
}
