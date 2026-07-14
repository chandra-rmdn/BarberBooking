import 'package:cloud_firestore/cloud_firestore.dart';

/// Lama waktu reservasi berstatus "Pending" sebelum otomatis dianggap
/// kadaluarsa karena barbershop belum sempat approve/reject.
/// Ubah durasinya di sini kalau mau beda.
const Duration kReservationConfirmationWindow = Duration(minutes: 15);

class ReservationModel {
  final String? id;

  final String userId;

  final String name;

  final String phone;

  final String bookingDate;

  final String bookingTime;

  final int bookingTimeMinutes;

  final String status;

  final Timestamp? createdAt;

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
  });
 
  /// Batas waktu sampai reservasi ini harus dikonfirmasi (approve/reject)
  /// oleh barbershop. Null kalau createdAt belum ke-resolve dari server
  /// (biasanya sesaat setelah dibuat, sebelum serverTimestamp() menetap).
  DateTime? get expiresAt {
    if (createdAt == null) return null;
    return createdAt!.toDate().add(kReservationConfirmationWindow);
  }

  /// True kalau reservasi masih Pending dan sudah lewat batas waktu.
  bool get isExpired {
    final exp = expiresAt;
    if (status != 'Pending' || exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

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
      createdAt: data["createdAt"],
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
    };
  }
}