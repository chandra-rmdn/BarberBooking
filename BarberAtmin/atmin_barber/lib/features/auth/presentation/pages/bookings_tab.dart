import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/reservation_model.dart';
import '../../../../services/reservation_service.dart';
import '../../../../services/notification_service.dart';

// ===========================================================================
// KONTEN TAB 1: BOOKINGS
// ===========================================================================
class BookingsTab extends StatefulWidget {
  const BookingsTab();

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final ReservationService _reservationService = ReservationService();
  final NotificationService _notificationService = NotificationService();

  String _activeFilter = "All";
  String _search = "";

  final Map<String, String> _statusMap = const {
    "Waiting": "Pending",
    "Confirmed": "Approved",
    "Rejected": "Rejected",
    "Done": "Completed",
    "Cancelled": "CancelledByCustomer",
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _search = value.toLowerCase().trim();
              });
            },
            decoration: InputDecoration(
              hintText: "Cari nama atau WhatsApp...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterCapsule("All"),
              _buildFilterCapsule("Waiting"),
              _buildFilterCapsule("Confirmed"),
              _buildFilterCapsule("Rejected"),
              _buildFilterCapsule("Done"),
              _buildFilterCapsule("Cancelled"),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<ReservationModel>>(
            stream: _reservationService.getAllReservations(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Terjadi kesalahan: ${snapshot.error}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F3773)),
                );
              }

              final allReservations = snapshot.data ?? [];

              final filteredReservations = allReservations.where((reservation) {
                final statusMatch =
                    _activeFilter == "All" ||
                    reservation.status == _statusMap[_activeFilter];

                final keyword = "${reservation.name} ${reservation.phone}"
                    .toLowerCase();

                final searchMatch = keyword.contains(_search);

                return statusMatch && searchMatch;
              }).toList();

              if (filteredReservations.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Belum ada reservasi untuk filter ini.",
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredReservations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBookingCard(filteredReservations[index]),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFilterCapsule(String text) {
    final bool isActive = _activeFilter == text;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = text),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F3773) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0F3773) : const Color(0xFFCBD3E1),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(ReservationModel reservation) {
    final String name = reservation.name;
    final String phone = reservation.phone;
    final String time = reservation.bookingTime;
    final String rawDate = reservation.bookingDate;
    final String status = reservation.status;

    String displayDate = rawDate;
    try {
      final parsed = DateTime.parse(rawDate);
      displayDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {}

    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    bool showApproveReject = false;
    bool showComplete = false;

    switch (status) {
      case 'Pending':
        statusText = "Waiting";
        statusBgColor = const Color(0xFFFFEAD2);
        statusTextColor = const Color(0xFFFF9F43);
        showApproveReject = true;
        break;
      case 'Approved':
        statusText = "Confirmed";
        statusBgColor = const Color(0xFFD4EDDA);
        statusTextColor = const Color(0xFF28A745);
        showComplete = true;
        break;
      case 'Rejected':
        statusText = "Rejected";
        statusBgColor = const Color(0xFFF8D7DA);
        statusTextColor = const Color(0xFFDC3545);
        break;
      case 'Completed':
        statusText = "Done";
        statusBgColor = const Color(0xFFE2E3E5);
        statusTextColor = Colors.grey;
        break;
      case 'CancelledByCustomer':
        statusText = "Cancelled";
        statusBgColor = const Color(0xFFE2E3E5);
        statusTextColor = Colors.grey;
        break;
      default:
        statusText = status;
        statusBgColor = const Color(0xFFE2E3E5);
        statusTextColor = Colors.grey;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showReservationDetail(reservation);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E9F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0F3773),
                      radius: 18,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusTextColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRowDetail("WhatsApp", phone),
            const SizedBox(height: 8),
            _buildRowDetail("Date", displayDate),
            const SizedBox(height: 8),
            _buildRowDetail("Time", time),
            if (showApproveReject) ...[
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    label: "Confirm",
                    icon: Icons.check,
                    color: const Color(0xFF28A745),
                    bgColor: const Color(0xFFD4EDDA),
                    onTap: () {
                      _showConfirmBookingDialog(reservation);
                    },
                  ),

                  _buildActionButton(
                    label: "Reject",
                    icon: Icons.close,
                    color: const Color(0xFFDC3545),
                    bgColor: const Color(0xFFF8D7DA),
                    onTap: () {
                      _showRejectBookingDialog(reservation);
                    },
                  ),
                ],
              ),
            ],

            if (showComplete) ...[
              const SizedBox(height: 16),

              Center(
                child: _buildActionButton(
                  label: "Complete",
                  icon: Icons.check_circle,
                  color: const Color(0xFF0F3773),
                  bgColor: const Color(0xFFCDE8FC),
                  onTap: () {
                    _showConfirmationDialog(
                      title: "Selesaikan Reservasi",
                      message:
                          "Reservasi milik\n\n${reservation.name}\n\nsudah selesai?",
                      color: const Color(0xFF0F3773),
                      onConfirm: () async {
                        await _completeReservation(reservation.id!);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReservationDetail(ReservationModel reservation) {
    String label = reservation.status;
    Color color = Colors.grey;

    switch (reservation.status) {
      case "Pending":
        label = "Waiting";
        color = const Color(0xFFFF9F43);
        break;
      case "Approved":
        label = "Confirmed";
        color = const Color(0xFF28A745);
        break;
      case "Rejected":
        label = "Rejected";
        color = const Color(0xFFDC3545);
        break;
      case "Completed":
        label = "Done";
        color = Colors.grey;
        break;
      case "CancelledByCustomer":
        label = "Cancelled";
        color = Colors.grey;
        break;
    }

    String displayDate = reservation.bookingDate;

    try {
      displayDate = DateFormat(
        "EEEE, d MMMM yyyy",
        "id_ID",
      ).format(DateTime.parse(reservation.bookingDate));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detail Reservasi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCDE8FC),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Status", label, valueColor: color),

                      const SizedBox(height: 10),

                      _buildDetailRow("Tanggal", displayDate),

                      const SizedBox(height: 10),

                      _buildDetailRow("Jam", reservation.bookingTime),

                      const SizedBox(height: 10),

                      _buildDetailRow("Atas nama", reservation.name),

                      const SizedBox(height: 10),

                      _buildDetailRow("Telepon", reservation.phone),

                      if (reservation.createdAt != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          "Dibuat",
                          DateFormat(
                            "EEEE dd MMM yyyy",
                            "id_ID",
                          ).format(reservation.createdAt!),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Tutup",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmBookingDialog(ReservationModel reservation) {
    String displayDate = reservation.bookingDate;

    try {
      displayDate = DateFormat(
        "EEEE, d MMMM yyyy",
        "id_ID",
      ).format(DateTime.parse(reservation.bookingDate));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Konfirmasi Reservasi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Apakah Anda yakin ingin mengonfirmasi reservasi ini?",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCDE8FC),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Tanggal", displayDate),

                      const SizedBox(height: 10),

                      _buildDetailRow("Jam", reservation.bookingTime),

                      const SizedBox(height: 10),

                      _buildDetailRow("Atas nama", reservation.name),

                      const SizedBox(height: 10),

                      _buildDetailRow("Telepon", reservation.phone),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFF0F3773),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          await _approveReservation(reservation);

                          _showTopBanner(
                            context,
                            message: "Reservasi berhasil dikonfirmasi.",
                          );
                        },
                        child: const Text(
                          "Konfirmasi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectBookingDialog(ReservationModel reservation) {
    String displayDate = reservation.bookingDate;

    try {
      displayDate = DateFormat(
        "EEEE, d MMMM yyyy",
        "id_ID",
      ).format(DateTime.parse(reservation.bookingDate));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tolak Reservasi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Apakah Anda yakin ingin menolak reservasi ini?",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCDE8FC),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow("Tanggal", displayDate),

                      const SizedBox(height: 10),

                      _buildDetailRow("Jam", reservation.bookingTime),

                      const SizedBox(height: 10),

                      _buildDetailRow("Atas nama", reservation.name),

                      const SizedBox(height: 10),

                      _buildDetailRow("Telepon", reservation.phone),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFFDC3545),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          await _rejectReservation(reservation);

                          _showTopBanner(
                            context,
                            message: "Reservasi berhasil ditolak.",
                          );
                        },
                        child: const Text(
                          "Tolak",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showTopBanner(
    BuildContext context, {
    required String message,
    Color backgroundColor = const Color(0xFF22C55E),
  }) {
    final overlay = Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 40,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _approveReservation(ReservationModel reservation) async {
    try {
      await _reservationService.approveReservation(reservation.id!);
      await _notificationService.createApprovedNotification(
        userId: reservation.userId,
        reservationId: reservation.id!,
        bookingDate: reservation.bookingDate,
        bookingTime: reservation.bookingTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reservasi berhasil disetujui")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error : $e")));
      }
    }
  }

  Future<void> _rejectReservation(ReservationModel reservation) async {
    try {
      await _reservationService.rejectReservation(reservation.id!);
      await _notificationService.createRejectedNotification(
        userId: reservation.userId,
        reservationId: reservation.id!,
        bookingDate: reservation.bookingDate,
        bookingTime: reservation.bookingTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reservasi berhasil ditolak")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error : $e")));
      }
    }
  }

  Future<void> _completeReservation(String reservationId) async {
    try {
      await _reservationService.completeReservation(reservationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reservasi selesai")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error : $e")));
      }
    }
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required Color color,
    required Future<void> Function() onConfirm,
  }) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                await onConfirm();
              },
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
