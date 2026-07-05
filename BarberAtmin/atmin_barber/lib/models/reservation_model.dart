import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String? id;

  final String userId;

  final String name;

  final String phone;

  final String bookingDate;

  final String bookingTime;

  final int bookingTimeMinutes;

  final String status;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  ReservationModel({
    this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.bookingDate,
    required this.bookingTime,
    required this.bookingTimeMinutes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReservationModel(
      id: doc.id,
      userId: data["userId"] ?? "",
      name: data["name"] ?? "",
      phone: data["phone"] ?? "",
      bookingDate: data["bookingDate"] ?? "",
      bookingTime: data["bookingTime"] ?? "",
      bookingTimeMinutes: data["bookingTimeMinutes"] ?? 0,
      status: data["status"] ?? "Pending",
      createdAt: (data["createdAt"] as Timestamp?)?.toDate(),
      updatedAt: (data["updatedAt"] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "name": name,
      "phone": phone,
      "bookingDate": bookingDate,
      "bookingTime": bookingTime,
      "bookingTimeMinutes": bookingTimeMinutes,
      "status": status,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
}
