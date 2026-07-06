import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/reservation_model.dart';
import '../../../../models/schedule_model.dart';
import '../../../../models/store_settings_model.dart';
import '../../../../services/reservation_service.dart';
import '../../../../services/schedule_sevice.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB9DDF5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () {},
          ),
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Color(0xFF0F3773),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF0F3773),
            indicatorWeight: 3,
            labelColor: Color(0xFF0F3773),
            unselectedLabelColor: Colors.black45,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Bookings"),
              Tab(text: "Schedules"),
            ],
          ),
        ),
        body: const TabBarView(children: [_BookingsTab(), _SchedulesTab()]),
      ),
    );
  }
}

// ===========================================================================
// KONTEN TAB 1: BOOKINGS
// ===========================================================================
class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  final ReservationService _reservationService = ReservationService();

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
              final total = allReservations.length;

              final filteredReservations = allReservations.where((reservation) {
                final statusMatch =
                    _activeFilter == "All" ||
                    reservation.status == _statusMap[_activeFilter];

                final keyword = "${reservation.name} ${reservation.phone}"
                    .toLowerCase();

                final searchMatch = keyword.contains(_search);

                return statusMatch && searchMatch;
              }).toList();

              final pending = allReservations
                  .where((e) => e.status == "Pending")
                  .length;

              final approved = allReservations
                  .where((e) => e.status == "Approved")
                  .length;

              final rejected = allReservations
                  .where((e) => e.status == "Rejected")
                  .length;

              final completed = allReservations
                  .where((e) => e.status == "Completed")
                  .length;

              final cancelled = allReservations.where((e) {
                return e.status == "CancelledByCustomer" ||
                    e.status == "CancelledByAdmin";
              }).length;

              if (filteredReservations.isEmpty) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Total",
                              value: total.toString(),
                              color: Colors.blue,
                              icon: Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: "Pending",
                              value: pending.toString(),
                              color: Colors.orange,
                              icon: Icons.schedule,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Approved",
                              value: approved.toString(),
                              color: Colors.green,
                              icon: Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: "Rejected",
                              value: rejected.toString(),
                              color: Colors.redAccent,
                              icon: Icons.cancel,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: "Done",
                              value: completed.toString(),
                              color: Colors.grey,
                              icon: Icons.done_all,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: "Cancelled",
                              value: cancelled.toString(),
                              color: Colors.red,
                              icon: Icons.block,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Belum ada reservasi untuk filter ini.",
                          style: TextStyle(color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total",
                            value: total.toString(),
                            color: Colors.blue,
                            icon: Icons.calendar_today,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Pending",
                            value: pending.toString(),
                            color: Colors.orange,
                            icon: Icons.schedule,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Approved",
                            value: approved.toString(),
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Rejected",
                            value: rejected.toString(),
                            color: Colors.red,
                            icon: Icons.cancel,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Completed",
                            value: completed.toString(),
                            color: Colors.blueGrey,
                            icon: Icons.done_all,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: "Cancelled",
                            value: cancelled.toString(),
                            color: Colors.grey,
                            icon: Icons.block,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredReservations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildBookingCard(filteredReservations[index]),
                        );
                      },
                    ),
                  ],
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F3773) : const Color(0xFF90C2E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0F3773), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF0F3773),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
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

                          await _approveReservation(reservation.id!);

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

                          await _rejectReservation(reservation.id!);

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

  Future<void> _approveReservation(String reservationId) async {
    try {
      await _reservationService.approveReservation(reservationId);

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

  Future<void> _rejectReservation(String reservationId) async {
    try {
      await _reservationService.rejectReservation(reservationId);

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

// ===========================================================================
// KONTEN TAB 2: SCHEDULES (sekarang nyambung ke Firestore koleksi 'store_settings')
// ===========================================================================
class _SchedulesTab extends StatefulWidget {
  const _SchedulesTab();

  @override
  State<_SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends State<_SchedulesTab> {
  final ScheduleService _scheduleService = ScheduleService();
  final ReservationService _reservationService = ReservationService();

  StoreSettingsModel? _settings;

  Map<String, ScheduleModel> _defaultSchedules = {};
  List<Map<String, dynamic>> _specialSchedules = [];

  bool _loading = true;

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, "0");
    final minute = (minutes % 60).toString().padLeft(2, "0");

    return "$hour:$minute";
  }

  int _parseTime(String time) {
    final split = time.split(":");
    return int.parse(split[0]) * 60 + int.parse(split[1]);
  }

  final List<String> _days = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _settings = await _scheduleService.getStoreSettings();
    _defaultSchedules.clear();

    for (final day in _days) {
      final schedule = await _scheduleService.getDefaultSchedule(day);

      if (schedule != null) {
        _defaultSchedules[day] = schedule;
      }
    }

    _specialSchedules = await _scheduleService.getSpecialSchedules();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _showEditScheduleDialog(String day) async {
    final schedule = _defaultSchedules[day];

    if (schedule == null) return;

    bool isOpen = schedule.isOpen;

    final openController = TextEditingController(
      text: _formatMinutes(schedule.openMinutes),
    );

    final closeController = TextEditingController(
      text: _formatMinutes(schedule.closeMinutes),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(day.toUpperCase()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: isOpen,
                      title: const Text("Hari Buka"),
                      onChanged: (value) {
                        setDialogState(() {
                          isOpen = value;
                        });
                      },
                    ),

                    TextField(
                      controller: openController,
                      readOnly: true,
                      onTap: () => _pickTime(context, openController),
                      decoration: const InputDecoration(
                        labelText: "Jam Buka",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: closeController,
                      readOnly: true,
                      onTap: () => _pickTime(context, closeController),
                      decoration: const InputDecoration(
                        labelText: "Jam Tutup",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Batal"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final openMinutes = _parseTime(openController.text);
                    final closeMinutes = _parseTime(closeController.text);
                    final newSchedule = ScheduleModel(
                      isOpen: isOpen,
                      openMinutes: openMinutes,
                      closeMinutes: closeMinutes,
                      name: "",
                      reason: "",
                      type: "custom",
                    );

                    if (closeMinutes <= openMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Jam tutup harus lebih besar dari jam buka.",
                          ),
                        ),
                      );
                      return;
                    }

                    await _scheduleService.updateDefaultSchedule(
                      day,
                      newSchedule,
                    );

                    await _loadData();

                    if (mounted) {
                      Navigator.pop(context);
                      _showTopBanner(
                        context,
                        message: "Schedule berhasil diperbarui.",
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddSpecialScheduleDialog() async {
    DateTime selectedDate = DateTime.now();
    bool isOpen = true;
    String type = "custom";

    final nameController = TextEditingController();
    final reasonController = TextEditingController();
    final openController = TextEditingController(text: "09:00");
    final closeController = TextEditingController(text: "20:00");

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Special Schedule"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        DateFormat(
                          "EEEE, d MMM yyyy",
                          "id_ID",
                        ).format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),

                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: selectedDate,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Alasan",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      children: [
                        RadioListTile<String>(
                          value: "closed",
                          groupValue: type,
                          title: const Text("Closed"),
                          onChanged: (value) {
                            setDialogState(() {
                              type = value!;
                            });
                          },
                        ),

                        RadioListTile<String>(
                          value: "custom",
                          groupValue: type,
                          title: const Text("Custom Hours"),
                          onChanged: (value) {
                            setDialogState(() {
                              type = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    if (type == "custom") ...[
                      TextField(
                        controller: openController,
                        readOnly: true,
                        onTap: () => _pickTime(context, openController),
                        decoration: const InputDecoration(
                          labelText: "Jam Buka",
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: closeController,
                        readOnly: true,
                        onTap: () => _pickTime(context, closeController),
                        decoration: const InputDecoration(
                          labelText: "Jam Tutup",
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Batal"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final schedule = ScheduleModel(
                      name: nameController.text.trim(),
                      reason: reasonController.text.trim(),
                      type: type,

                      isOpen: type == "custom",

                      openMinutes: type == "custom"
                          ? _parseTime(openController.text)
                          : 0,

                      closeMinutes: type == "custom"
                          ? _parseTime(closeController.text)
                          : 0,
                    );

                    final total = await _reservationService
                        .countActiveReservationByDate(selectedDate);

                    if (total > 0) {
                      final lanjut = await _showReservationWarning(total);

                      if (!lanjut) {
                        return;
                      }
                    }

                    if (isOpen) {
                      await _reservationService
                          .cancelReservationsOutsideSchedule(
                            date: selectedDate,
                            openMinutes: schedule.openMinutes,
                            closeMinutes: schedule.closeMinutes,
                          );
                    }

                    await _scheduleService.saveSpecialSchedule(
                      date: selectedDate,
                      schedule: schedule,
                    );

                    await _loadData();

                    if (!mounted) return;

                    Navigator.pop(context);
                    _showTopBanner(
                      context,
                      message: "Special Schedule berhasil ditambahkan.",
                    );
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditSpecialScheduleDialog(Map<String, dynamic> item) async {
    DateTime selectedDate = DateTime.parse(item["id"]);
    bool isOpen = item["isOpen"];
    String type = item["type"] ?? "custom";

    final openController = TextEditingController(
      text: _formatMinutes(item["openMinutes"]),
    );
    final closeController = TextEditingController(
      text: _formatMinutes(item["closeMinutes"]),
    );
    final nameController = TextEditingController(text: item["name"] ?? "");
    final reasonController = TextEditingController(text: item["reason"] ?? "");

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Special Schedule"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        DateFormat(
                          "EEEE, d MMM yyyy",
                          "id_ID",
                        ).format(selectedDate),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nama",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Alasan",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    Column(
                      children: [
                        RadioListTile<String>(
                          value: "closed",
                          groupValue: type,
                          title: const Text("Closed"),
                          onChanged: (value) {
                            setDialogState(() {
                              type = value!;
                            });
                          },
                        ),

                        RadioListTile<String>(
                          value: "custom",
                          groupValue: type,
                          title: const Text("Custom Hours"),
                          onChanged: (value) {
                            setDialogState(() {
                              type = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    if (type == "custom") ...[
                      TextField(
                        controller: openController,
                        readOnly: true,
                        onTap: () => _pickTime(context, openController),
                        decoration: const InputDecoration(
                          labelText: "Jam Buka",
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: closeController,
                        readOnly: true,
                        onTap: () => _pickTime(context, closeController),
                        decoration: const InputDecoration(
                          labelText: "Jam Tutup",
                          suffixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Batal"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final schedule = ScheduleModel(
                      name: nameController.text.trim(),
                      reason: reasonController.text.trim(),
                      type: type,

                      isOpen: type == "custom",

                      openMinutes: type == "custom"
                          ? _parseTime(openController.text)
                          : 0,

                      closeMinutes: type == "custom"
                          ? _parseTime(closeController.text)
                          : 0,
                    );

                    final total = await _reservationService
                        .countActiveReservationByDate(selectedDate);

                    if (total > 0) {
                      final lanjut = await _showReservationWarning(total);

                      if (!lanjut) {
                        return;
                      }
                    }

                    if (isOpen) {
                      await _reservationService
                          .cancelReservationsOutsideSchedule(
                            date: selectedDate,
                            openMinutes: schedule.openMinutes,
                            closeMinutes: schedule.closeMinutes,
                          );
                    }

                    await _scheduleService.saveSpecialSchedule(
                      date: selectedDate,
                      schedule: schedule,
                    );

                    await _loadData();

                    if (!mounted) return;

                    Navigator.pop(context);

                    _showTopBanner(
                      context,
                      message: "Special Schedule berhasil diperbarui.",
                    );
                  },

                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showReservationWarning(int total) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Konfirmasi"),

          content: Text(
            "Terdapat $total reservasi aktif pada tanggal tersebut.\n\n"
            "Perubahan jadwal dapat membatalkan reservasi pelanggan.\n\n"
            "Apakah Anda yakin ingin melanjutkan?",
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),

            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Tetap Simpan"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);

    try {
      final split = controller.text.split(":");
      initialTime = TimeOfDay(
        hour: int.parse(split[0]),
        minute: int.parse(split[1]),
      );
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      controller.text =
          "${picked.hour.toString().padLeft(2, '0')}:"
          "${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F3773)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreCard(),

          const SizedBox(height: 24),

          _buildWeeklySchedule(),

          const SizedBox(height: 24),

          _buildSpecialSchedule(),
        ],
      ),
    );
  }

  Widget _buildStoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Store Settings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F3773),
            ),
          ),

          const SizedBox(height: 16),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Store Open"),
            value: _settings!.isStoreOpen,
            onChanged: (value) async {
              final newSettings = _settings!.copyWith(isStoreOpen: value);

              await _scheduleService.updateStoreSettings(newSettings);

              setState(() {
                _settings = newSettings;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Weekly Schedule",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F3773),
          ),
        ),

        const SizedBox(height: 16),

        ..._days.map((day) {
          final schedule = _defaultSchedules[day];

          if (schedule == null) {
            return const SizedBox();
          }

          final hours =
              "${_formatMinutes(schedule.openMinutes)} - ${_formatMinutes(schedule.closeMinutes)}";

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                schedule.isOpen ? Icons.lock_open : Icons.lock_outline,
              ),

              title: Text(day.toUpperCase()),

              subtitle: Text(schedule.isOpen ? hours : "Closed"),

              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditScheduleDialog(day);
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSpecialSchedule() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Special Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddSpecialScheduleDialog,
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_specialSchedules.isEmpty)
            const Text(
              "Belum ada special schedule",
              style: TextStyle(color: Colors.grey),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _specialSchedules.length,
              itemBuilder: (context, index) {
                final item = _specialSchedules[index];

                final date = item["id"];

                final isOpen = item["isOpen"];

                final open = _formatMinutes(item["openMinutes"]);

                final close = _formatMinutes(item["closeMinutes"]);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                (item["name"] ?? "").toString().isEmpty
                                    ? "Tanpa Nama"
                                    : item["name"],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event,
                                  size: 18,
                                  color: Color(0xFF0F3773),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    "EEEE, d MMM yyyy",
                                    "id_ID",
                                  ).format(DateTime.parse(date)),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        if ((item["reason"] ?? "").toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item["reason"],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOpen ? "Custom Hours ($open - $close)" : "Closed",
                            style: TextStyle(
                              color: isOpen
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditSpecialScheduleDialog(item);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Hapus Special Schedule"),
                                    content: const Text(
                                      "Apakah Anda yakin ingin menghapus Special Schedule ini?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Hapus"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                final parsed = DateTime.parse(date);

                                await _scheduleService.deleteSpecialSchedule(
                                  parsed,
                                );

                                await _loadData();

                                if (!mounted) return;

                                _showTopBanner(
                                  context,
                                  message: "Special Schedule berhasil dihapus.",
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
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
}
