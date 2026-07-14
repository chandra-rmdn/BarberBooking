import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _formatDate(String bookingDate) {
    return DateFormat(
      "EEEE, d MMMM yyyy",
      "id_ID",
    ).format(DateTime.parse(bookingDate));
  }

  String _formatTime(String bookingTime) {
    return bookingTime.replaceAll(":", ".");
  }

  Future<void> createNotification({
    required String userId,
    required String reservationId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _firestore.collection("notifications").add({
      "userId": userId,
      "reservationId": reservationId,
      "title": title,
      "body": body,
      "type": type,
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> createApprovedNotification({
    required String userId,
    required String reservationId,
    required String bookingDate,
    required String bookingTime,
  }) async {
    await createNotification(
      userId: userId,
      reservationId: reservationId,
      title: "Reservasi Dikonfirmasi",
      body:
          "Reservasi Anda pada ${_formatDate(bookingDate)} pukul ${_formatTime(bookingTime)} telah dikonfirmasi.",
      type: "approved",
    );
  }

  Future<void> createRejectedNotification({
    required String userId,
    required String reservationId,
    required String bookingDate,
    required String bookingTime,
  }) async {
    await createNotification(
      userId: userId,
      reservationId: reservationId,
      title: "Reservasi Ditolak",
      body:
          "Maaf, reservasi Anda pada ${_formatDate(bookingDate)} pukul ${_formatTime(bookingTime)} ditolak.",
      type: "rejected",
    );
  }

  Future<void> createCancelledNotification({
    required String userId,
    required String reservationId,
    required String bookingDate,
    required String bookingTime,
  }) async {
    await createNotification(
      userId: userId,
      reservationId: reservationId,
      title: "Reservasi Dibatalkan",
      body:
          "Reservasi Anda pada ${_formatDate(bookingDate)} pukul ${_formatTime(bookingTime)} dibatalkan karena perubahan jadwal operasional barbershop.",
      type: "cancelled",
    );
  }

  Future<void> createCompletedNotification({
    required String userId,
    required String reservationId,
    required String bookingDate,
    required String bookingTime,
  }) async {
    await createNotification(
      userId: userId,
      reservationId: reservationId,
      title: "Reservasi Selesai",
      body:
          "Terima kasih telah menggunakan layanan Jamal Barbershop. Reservasi Anda pada $bookingDate pukul $bookingTime telah selesai.",
      type: "completed",
    );
  }

  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUnreadNotifications(String userId) {
    return _firestore
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .snapshots();
  }

  Future<void> markAsRead(String id) async {
    await _firestore.collection("notifications").doc(id).update({
      "isRead": true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"isRead": true});
    }

    await batch.commit();
  }
}
