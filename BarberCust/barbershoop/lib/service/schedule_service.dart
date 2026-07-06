import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbershoop/models/schedule_model.dart';
import 'package:barbershoop/models/store_settings_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ==========================================================
  /// STORE SETTINGS
  /// ==========================================================

  Future<StoreSettingsModel> getStoreSettings() async {
    final doc = await _firestore.collection('store_settings').doc('main').get();

    if (!doc.exists) {
      throw Exception("Store settings tidak ditemukan.");
    }

    return StoreSettingsModel.fromMap(doc.data()!);
  }

  /// ==========================================================
  /// UPDATE STORE SETTINGS
  /// ==========================================================

  Future<void> updateStoreSettings(StoreSettingsModel settings) async {
    await _firestore
        .collection("store_settings")
        .doc("main")
        .update(settings.toMap());
  }

  /// ==========================================================
  /// DEFAULT SCHEDULE
  /// ==========================================================

  Future<ScheduleModel?> getDefaultSchedule(String day) async {
    final doc = await _firestore.collection('default_schedule').doc(day).get();
    if (!doc.exists) return null;

    return ScheduleModel.fromMap(doc.data()!);
  }

  /// ==========================================================
  /// UPDATE DEFAULT SCHEDULE
  /// ==========================================================

  Future<void> updateDefaultSchedule(String day, ScheduleModel schedule) async {
    await _firestore
        .collection("default_schedule")
        .doc(day)
        .set(schedule.toMap());
  }

  /// ==========================================================
  /// SPECIAL SCHEDULE
  /// ==========================================================

  Future<ScheduleModel?> getSpecialSchedule(DateTime date) async {
    final id =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final doc = await _firestore.collection('special_schedule').doc(id).get();

    if (!doc.exists) return null;

    return ScheduleModel.fromMap(doc.data()!);
  }

  /// ==========================================================
  /// DAY NAME
  /// ==========================================================

  String _dayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return "monday";
      case DateTime.tuesday:
        return "tuesday";
      case DateTime.wednesday:
        return "wednesday";
      case DateTime.thursday:
        return "thursday";
      case DateTime.friday:
        return "friday";
      case DateTime.saturday:
        return "saturday";
      default:
        return "sunday";
    }
  }

  /// ==========================================================
  /// FINAL SCHEDULE
  /// (Special Schedule lebih prioritas)
  /// ==========================================================

  Future<ScheduleModel?> getSchedule(DateTime date) async {
    final settings = await getStoreSettings();

    // Prioritas 1 : Store Open (Global)
    if (!settings.isStoreOpen) {
      return ScheduleModel(isOpen: false, openMinutes: 0, closeMinutes: 0);
    }

    // Prioritas 2 : Special Schedule
    final special = await getSpecialSchedule(date);

    if (special != null) {
      return special;
    }

    // Prioritas 3 : Weekly Schedule
    final day = _dayName(date);

    return await getDefaultSchedule(day);
  }

  /// ==========================================================
  /// SLOT GENERATOR
  /// ==========================================================

  List<int> generateSlots({
    required int openMinutes,
    required int closeMinutes,
    required int slotDurationMinutes,
  }) {
    List<int> slots = [];

    for (
      int minute = openMinutes;
      minute < closeMinutes;
      minute += slotDurationMinutes
    ) {
      slots.add(minute);
    }

    return slots;
  }

  /// ==========================================================
  /// FORMAT
  /// ==========================================================

  String formatMinutes(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    return "${hour.toString().padLeft(2, '0')}:"
        "${minute.toString().padLeft(2, '0')}";
  }

  /// ==========================================================
  /// BOOKING WINDOW
  /// ==========================================================

  Future<bool> isDateAllowed(DateTime selectedDate) async {
    final settings = await getStoreSettings();

    final maxBookingDays = settings.maxBookingDays;

    final today = DateTime.now();

    final start = DateTime(today.year, today.month, today.day);

    final end = start.add(Duration(days: maxBookingDays));

    if (selectedDate.isBefore(start)) {
      return false;
    }

    if (selectedDate.isAfter(end)) {
      return false;
    }

    return true;
  }

  /// ==========================================================
  /// OPEN / CLOSE
  /// ==========================================================

  bool isOpen(ScheduleModel schedule) {
    return schedule.isOpen;
  }

  int getOpenMinutes(ScheduleModel schedule) {
    return schedule.openMinutes;
  }

  int getCloseMinutes(ScheduleModel schedule) {
    return schedule.closeMinutes;
  }

  int getSlotDuration(StoreSettingsModel settings) {
    return settings.slotDurationMinutes;
  }

  int getBookingBuffer(StoreSettingsModel settings) {
    return settings.bookingBufferMinutes;
  }

  /// ==========================================================
  /// TIME PARSER
  /// ==========================================================

  int parseTimeToMinutes(String time) {
    final parts = time.split(':');

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return hour * 60 + minute;
  }
}
