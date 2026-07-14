import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;

  final String userId;

  final String reservationId;

  final String title;

  final String body;

  final String type;

  final bool isRead;

  final Timestamp? createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.reservationId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data["userId"] ?? "",
      reservationId: data["reservationId"] ?? "",
      title: data["title"] ?? "",
      body: data["body"] ?? "",
      type: data["type"] ?? "",
      isRead: data["isRead"] ?? false,
      createdAt: data["createdAt"],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "reservationId": reservationId,
      "title": title,
      "body": body,
      "type": type,
      "isRead": isRead,
      "createdAt": createdAt,
    };
  }
}