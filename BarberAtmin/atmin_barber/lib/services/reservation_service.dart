import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atmin_barber/models/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ==========================================================
  /// CREATE RESERVATION
  /// ==========================================================
  Future<void> createReservation({
    required String userId,
    required String name,
    required String phone,
    required DateTime bookingDate,
    required String bookingTime,
  }) async {
    final formattedDate =
        "${bookingDate.year.toString().padLeft(4, '0')}-"
        "${bookingDate.month.toString().padLeft(2, '0')}-"
        "${bookingDate.day.toString().padLeft(2, '0')}";

    final bookingTimeMinutes = bookingTime.split(':').map(int.parse).toList();

    final totalMinutes = bookingTimeMinutes[0] * 60 + bookingTimeMinutes[1];

    final available = await isSlotAvailable(
      bookingDate: formattedDate,
      bookingTime: bookingTime,
    );

    if (!available) {
      throw Exception("Slot sudah dipakai, silakan pilih jam lain.");
    }

    await _firestore.collection("reservations").add({
      "userId": userId,

      "name": name,

      "phone": phone,

      "bookingDate": formattedDate,

      "bookingTime": bookingTime,

      "bookingTimeMinutes": totalMinutes,

      "status": "Pending",

      "createdAt": FieldValue.serverTimestamp(),

      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ==========================================================
  /// CANCEL BY CUSTOMER
  /// ==========================================================
  Future<void> cancelReservation(String reservationId) async {
    await _firestore.collection("reservations").doc(reservationId).update({
      "status": "CancelledByCustomer",
      "cancelledAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ==========================================================
  /// APPROVE
  /// ==========================================================
  Future<void> approveReservation(String reservationId) async {
    await _firestore.collection("reservations").doc(reservationId).update({
      "status": "Approved",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ==========================================================
  /// REJECT
  /// ==========================================================
  Future<void> rejectReservation(String reservationId) async {
    await _firestore.collection("reservations").doc(reservationId).update({
      "status": "Rejected",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ==========================================================
  /// COMPLETE
  /// ==========================================================
  Future<void> completeReservation(String reservationId) async {
    await _firestore.collection("reservations").doc(reservationId).update({
      "status": "Completed",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  /// ==========================================================
  /// SLOT KEY
  /// ==========================================================
  String slotKey(String bookingDate, String bookingTime) {
    return "${bookingDate}_$bookingTime";
  }

  /// ==========================================================
  /// CHECK SLOT
  /// ==========================================================
  Future<bool> isSlotAvailable({
    required String bookingDate,
    required String bookingTime,
  }) async {
    final snapshot = await _firestore
        .collection("reservations")
        .where("bookingDate", isEqualTo: bookingDate)
        .where("bookingTime", isEqualTo: bookingTime)
        .where("status", whereIn: ["Pending", "Approved"])
        .get();

    return snapshot.docs.isEmpty;
  }

  /// ==========================================================
  /// GET USER RESERVATIONS
  /// ==========================================================
  Stream<List<ReservationModel>> getUserReservations(String userId) {
    return _firestore
        .collection("reservations")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReservationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// ==========================================================
  /// GET ALL RESERVATIONS
  /// ==========================================================
  Stream<List<ReservationModel>> getAllReservations() {
    return _firestore
        .collection("reservations")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReservationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// ==========================================================
  /// GET RESERVATION BY ID
  /// ==========================================================
  Future<ReservationModel?> getReservation(String reservationId) async {
    final doc = await _firestore
        .collection("reservations")
        .doc(reservationId)
        .get();

    if (!doc.exists) return null;

    return ReservationModel.fromFirestore(doc);
  }
}
