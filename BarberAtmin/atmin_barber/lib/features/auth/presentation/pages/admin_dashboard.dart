import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../models/reservation_model.dart';
import '../../../../services/reservation_service.dart';

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

              final filteredReservations = _activeFilter == "All"
                  ? allReservations
                  : allReservations.where((reservation) {
                      return reservation.status == _statusMap[_activeFilter];
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                itemCount: filteredReservations.length,
                itemBuilder: (context, index) {
                  final reservation = filteredReservations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildBookingCard(reservation),
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
                  onTap: () => _approveReservation(reservation.id!),
                ),

                _buildActionButton(
                  label: "Reject",
                  icon: Icons.close,
                  color: const Color(0xFFDC3545),
                  bgColor: const Color(0xFFF8D7DA),
                  onTap: () => _rejectReservation(reservation.id!),
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
                onTap: () => _completeReservation(reservation.id!),
              ),
            ),
          ],
        ],
      ),
    );
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Satu dokumen tunggal untuk pengaturan toko, biar gampang diakses 2 app
  final DocumentReference _storeDoc = FirebaseFirestore.instance
      .collection('store_settings')
      .doc('main');

  final List<String> _dayOrder = const [
    "Senin",
    "Selasa",
    "Rabu",
    "Kamis",
    "Jumat",
    "Sabtu",
    "Minggu",
  ];

  // Default data kalau dokumen belum pernah dibuat di Firestore
  final Map<String, Map<String, dynamic>> _defaultSchedule = const {
    "Senin": {"isOpen": true, "hours": "09:00 - 20:00"},
    "Selasa": {"isOpen": true, "hours": "09:00 - 20:00"},
    "Rabu": {"isOpen": true, "hours": "09:00 - 20:00"},
    "Kamis": {"isOpen": true, "hours": "09:00 - 20:00"},
    "Jumat": {"isOpen": true, "hours": "09:00 - 20:00"},
    "Sabtu": {"isOpen": true, "hours": "08:00 - 21:00"},
    "Minggu": {"isOpen": false, "hours": "Tutup (Libur)"},
  };

  @override
  void initState() {
    super.initState();
    _ensureDocExists();
  }

  // Kalau dokumen 'main' belum ada, buat dulu dengan data default
  Future<void> _ensureDocExists() async {
    final snapshot = await _storeDoc.get();
    if (!snapshot.exists) {
      await _storeDoc.set({'isStoreOpen': true, 'schedule': _defaultSchedule});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _storeDoc.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F3773)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final bool isStoreOpen = data['isStoreOpen'] ?? true;
        final Map<String, dynamic> schedule = Map<String, dynamic>.from(
          data['schedule'] ?? _defaultSchedule,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KARTU MASTER BUKA/TUTUP ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isStoreOpen
                        ? const Color(0xFF28A745).withOpacity(0.5)
                        : const Color(0xFFDC3545).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status Toko Hari Ini",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isStoreOpen
                              ? "Menerima Reservasi (BUKA)"
                              : "Toko Sedang Tutup",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isStoreOpen
                                ? const Color(0xFF28A745)
                                : const Color(0xFFDC3545),
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isStoreOpen,
                      activeColor: const Color(0xFF0F3773),
                      onChanged: (value) {
                        _storeDoc.update({'isStoreOpen': value});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Jam Operasional Mingguan",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3773),
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dayOrder.length,
                itemBuilder: (context, index) {
                  final day = _dayOrder[index];
                  final dayData = Map<String, dynamic>.from(
                    schedule[day] ?? {"isOpen": true, "hours": "09:00 - 20:00"},
                  );
                  final bool dayIsOpen = dayData["isOpen"] ?? true;
                  final String hours = dayData["hours"] ?? "-";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: dayIsOpen
                                  ? const Color(0xFF0F3773)
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              day,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: dayIsOpen ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              hours,
                              style: TextStyle(
                                color: dayIsOpen
                                    ? Colors.black54
                                    : const Color(0xFFDC3545),
                                fontWeight: dayIsOpen
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showEditDayDialog(
                                day,
                                dayIsOpen,
                                hours,
                                schedule,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- POPUP EDIT JAM PER HARI ---
  void _showEditDayDialog(
    String day,
    bool currentIsOpen,
    String currentHours,
    Map<String, dynamic> fullSchedule,
  ) {
    bool tempIsOpen = currentIsOpen;
    final hoursController = TextEditingController(text: currentHours);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text("Edit Jadwal $day"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Buka di hari ini"),
                      Switch(
                        value: tempIsOpen,
                        activeColor: const Color(0xFF0F3773),
                        onChanged: (value) {
                          setDialogState(() => tempIsOpen = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hoursController,
                    enabled: tempIsOpen,
                    decoration: const InputDecoration(
                      labelText: "Jam operasional",
                      hintText: "Contoh: 09:00 - 20:00",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3773),
                  ),
                  onPressed: () async {
                    final updatedSchedule = Map<String, dynamic>.from(
                      fullSchedule,
                    );
                    updatedSchedule[day] = {
                      "isOpen": tempIsOpen,
                      "hours": tempIsOpen
                          ? hoursController.text.trim()
                          : "Tutup (Libur)",
                    };
                    await _storeDoc.update({'schedule': updatedSchedule});
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
