import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:barbershoop/models/reservation_model.dart';
import '../../../../service/reservation_service.dart';

class ReservasiSayaTab extends StatefulWidget {
  final VoidCallback onBuatReservasiPressed;

  const ReservasiSayaTab({Key? key, required this.onBuatReservasiPressed})
    : super(key: key);

  @override
  State<ReservasiSayaTab> createState() => ReservasiSayaTabState();
}

class ReservasiSayaTabState extends State<ReservasiSayaTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReservationService _reservationService = ReservationService();

  @override
  Widget build(BuildContext context) {
    String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Silakan login terlebih dahulu.'));
    }
    return StreamBuilder<List<ReservationModel>>(
      stream: _reservationService.getUserReservations(userId),
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
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Color(0xFF0F3773)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Daftar Reservasi Anda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Reservasi tersimpan di perangkat ini.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final reservation = snapshot.data![index];
                  return _buildReservationCard(context, reservation);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Daftar Reservasi Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reservasi tersimpan di perangkat ini.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFCDE8FC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFF0F3773),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada reservasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reservasi yang Anda buat akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: widget.onBuatReservasiPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3773),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Buat reservasi',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- CARD SATU RESERVASI (sesuai desain: jam + status, lalu tanggal & nama/telepon) ---
  Widget _buildReservationCard(
    BuildContext context,
    ReservationModel reservation,
  ) {
    final String status = reservation.status;
    final String time = reservation.bookingTime;
    final String name = reservation.name;
    final String phone = reservation.phone;
    final String rawDate = reservation.bookingDate;

    String displayDate = rawDate;
    try {
      final parsed = DateTime.parse(rawDate);
      displayDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      // kalau gagal parse, tampilkan raw date apa adanya
    }

    // Mapping status ke label & warna (status di Firestore disamakan ke bahasa Inggris ringkas)
    String label;
    Color color;
    switch (status) {
      case 'Pending':
        label = "Waiting";
        color = const Color(0xFFFF9F43);
        break;

      case 'Approved':
        label = "Confirmed";
        color = const Color(0xFF22C55E);
        break;

      case 'Rejected':
        label = "Rejected";
        color = const Color(0xFFEF4444);
        break;

      case 'Completed':
        label = "Done";
        color = const Color(0xFF6B7280);
        break;

      case 'CancelledByCustomer':
        label = "Cancelled";
        color = const Color(0xFF6B7280);
        break;

      default:
        label = status;
        color = const Color(0xFF0F3773);
    }

    return GestureDetector(
      onTap: () =>
          _showDetailDialog(context, reservation, label, color, displayDate),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3773),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              displayDate,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$name, $phone",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // --- POPUP DETAIL RESERVASI + TOMBOL BATAL ---
  void _showDetailDialog(
    BuildContext context,
    ReservationModel reservation,
    String label,
    Color color,
    String displayDate,
  ) {
    final bool bisaDibatalkan = label == "Waiting" || label == "Confirmed";

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ],
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
                      _buildDetailRow("Status", label, valueColor: color),
                      const SizedBox(height: 10),
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

                if (bisaDibatalkan)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _confirmCancel(context, reservation.id!),
                      child: const Text(
                        "Batalkan Reservasi",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Reservasi ini sudah tidak bisa dibatalkan",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 10),
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

  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // --- KONFIRMASI BATAL, LALU UPDATE STATUS DI FIRESTORE ---
  void _confirmCancel(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Batalkan Reservasi?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan kembali."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tidak", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await _reservationService.cancelReservation(docId);
              if (context.mounted) {
                Navigator.pop(context); // tutup dialog konfirmasi
                Navigator.pop(context); // tutup dialog detail
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Reservasi berhasil dibatalkan"),
                  ),
                );
              }
            },
            child: const Text(
              "Ya, Batalkan",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
