import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:atmin_barber/models/reservation_model.dart';
import 'notification_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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
  /// CANCEL BY ADMIN
  /// =========================================================

  Future<void> cancelReservationsByAdmin({required String bookingDate}) async {
    final snapshot = await _firestore
        .collection("reservations")
        .where("bookingDate", isEqualTo: bookingDate)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = (data["status"] ?? "").toString().toLowerCase();

      if (status == "pending" || status == "approved") {
        batch.update(doc.reference, {
          "status": "CancelledByAdmin",
          "updatedAt": FieldValue.serverTimestamp(),
          "cancelledAt": FieldValue.serverTimestamp(),
        });
        await _notificationService.createCancelledNotification(
          userId: data["userId"],
          reservationId: doc.id,
          bookingDate: data["bookingDate"],
          bookingTime: data["bookingTime"],
        );
      }
    }

    await batch.commit();
  }

  Future<void> cancelReservationsOutsideSchedule({
    required DateTime date,
    required int openMinutes,
    required int closeMinutes,
  }) async {
    final bookingDate =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final snapshot = await _firestore
        .collection("reservations")
        .where("bookingDate", isEqualTo: bookingDate)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = (data["status"] ?? "").toString().toLowerCase();

      if (status != "pending" && status != "approved") {
        continue;
      }

      final bookingMinutes = data["bookingTimeMinutes"] as int;

      if (bookingMinutes < openMinutes || bookingMinutes >= closeMinutes) {
        batch.update(doc.reference, {
          "status": "CancelledByAdmin",
          "updatedAt": FieldValue.serverTimestamp(),
          "cancelledAt": FieldValue.serverTimestamp(),
        });
        try {
          await _notificationService.createCancelledNotification(
            userId: data["userId"],
            reservationId: doc.id,
            bookingDate: data["bookingDate"],
            bookingTime: data["bookingTime"],
          );

          print("NOTIF BERHASIL ${doc.id}");
        } catch (e) {
          print("ERROR NOTIF : $e");
        }
      }
    }

    await batch.commit();
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

  Future<int> countActiveReservationByDate(DateTime date) async {
    final bookingDate =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final snapshot = await _firestore
        .collection("reservations")
        .where("bookingDate", isEqualTo: bookingDate)
        .get();

    return snapshot.docs.where((doc) {
      final status = (doc["status"] ?? "").toString().toLowerCase();

      return status == "pending" || status == "approved";
    }).length;
  }
}
