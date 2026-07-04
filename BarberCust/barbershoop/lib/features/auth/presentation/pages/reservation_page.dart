import 'package:barbershoop/features/auth/presentation/pages/my_reservation.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'package:barbershoop/service/schedule_service.dart';
import 'package:barbershoop/service/reservation_service.dart';
import 'package:barbershoop/models/schedule_model.dart';
import 'package:barbershoop/models/store_settings_model.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  int _currentTabIndex = 0; // Logika kamu yang ini sudah mantap!

  bool _isCalendarOpen = false;
  bool _isTimeBoxVisible = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String? _confirmedTime;

  // Jam yang sudah dipesan orang lain di tanggal yang dipilih (dari Firestore)
  List<String> _bookedTimes = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScheduleService _scheduleService = ScheduleService();
  final ReservationService _reservationService = ReservationService();

  // Data user dari Firestore (untuk header greeting & auto-isi form)
  String _userName = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    _selectedDay = today;
    _focusedDay = today;

    _loadUserData();
    _loadBookedTimes(today);
    _loadSchedule(today);
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
          _userPhone = doc.data()?['phone'] ?? '';
        });
      }
    } catch (_) {}
  }

  // Load jam yang sudah dipesan orang lain berdasarkan tanggal yang dipilih
  Future<void> _loadBookedTimes(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final uid = _auth.currentUser?.uid;
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('bookingDate', isEqualTo: formattedDate)
          .where('status', whereIn: ['Pending', 'Disetujui'])
          .get();

      final booked = snapshot.docs
          .where((doc) => doc.data()['userId'] != uid) // exclude punya sendiri
          .map((doc) => doc.data()['bookingTime'] as String)
          .toList();

      if (mounted) {
        setState(() {
          _bookedTimes = booked;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSchedule(DateTime date) async {
    final settings = await _scheduleService.getStoreSettings();

    final schedule = await _scheduleService.getSchedule(date);

    if (schedule == null) {
      setState(() {
        _availableTimes = [];
      });

      return;
    }

    if (!schedule.isOpen) {
      setState(() {
        _availableTimes = [];
      });

      return;
    }

    final slots = _scheduleService.generateSlots(
      openMinutes: schedule.openMinutes,
      closeMinutes: schedule.closeMinutes,
      slotDurationMinutes: settings.slotDurationMinutes,
    );

    setState(() {
      _storeSettings = settings;

      _currentSchedule = schedule;

      _availableTimes = slots
          .map((e) => _scheduleService.formatMinutes(e))
          .toList();
    });
  }

  // Hitung jumlah reservasi aktif (selain yang sudah dibatalkan) untuk badge di tab
  Stream<int> _reservationCountStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => (doc.data()['status'] ?? '') != 'Cancelled')
              .length,
        );
  }

  List<String> _availableTimes = [];
  StoreSettingsModel? _storeSettings;
  ScheduleModel? _currentSchedule;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFCDE8FC),
        body: SafeArea(
          child: SingleChildScrollView(
            // <-- Membungkus SEMUA, otomatis bisa di-scroll panjang kebawah
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // --- HEADER BARBERSHOP ---
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(
                              0xFFFF6B35,
                            ).withOpacity(0.2),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Halo, Selamat Datang!",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                _auth.currentUser?.displayName != null &&
                                        _auth
                                            .currentUser!
                                            .displayName!
                                            .isNotEmpty
                                    ? _auth.currentUser!.displayName!
                                    : "Pengguna",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F3773),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 🌟 NAVIGASI ICON GEAR KE PROFILE PAGE
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Color(0xFF0F3773),
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Badges
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Reservasi online 🔵 Cepat & Mudah",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline Utama
                const Text(
                  "Pesan jadwal potong\nrambut\ntanpa antri.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "pilih tanggal, pilih jam yang masih tersedia, lalu isi\ndata Anda sampai selesai.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 25),

                // --- TAB MENU ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: TabBar(
                      onTap: (index) {
                        setState(() {
                          _currentTabIndex = index;
                        });
                      },
                      indicator: BoxDecoration(
                        color: const Color(0xFF0F3773),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: [
                        const Tab(text: "Reservasi"),
                        Tab(
                          child: StreamBuilder<int>(
                            stream: _reservationCountStream(),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("Reservasi Saya"),
                                  if (count > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF6B35),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "$count",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- PENGKONDISIAN HALAMAN (Cara 1 yang sesungguhnya) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _currentTabIndex == 0
                      ? _buildReservationTabContent()
                      : ReservasiSayaTab(
                          onBuatReservasiPressed: () {
                            DefaultTabController.of(context).animateTo(0);
                            _currentTabIndex = 0;
                          },
                        ),
                ),
                const SizedBox(height: 40),

                // 🛑 DI SINI CONTAINER EXPANDED & TABBARVIEW LAMA SUDAH DIHAPUS TOTAL 🛑
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET KONTEN TAB 1: FORM RESERVASI
  // ===========================================================================
  Widget _buildReservationTabContent() {
    return Builder(
      builder: (context) {
        final bool isStoreOpen =
            _currentSchedule != null && (_currentSchedule!.isOpen);

        // Kalau toko baru tutup, reset semua state pilihan biar jam gak bisa diklik
        if (!isStoreOpen && (_isCalendarOpen || _isTimeBoxVisible)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isCalendarOpen = false;
                _isTimeBoxVisible = false;
                _selectedDay = null;
                _confirmedTime = null;
              });
            }
          });
        }

        return Column(
          children: [
            // --- BANNER TOKO TUTUP ---
            if (!isStoreOpen)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444), width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFFEF4444)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Toko sedang tutup. Reservasi belum bisa dilakukan saat ini.",
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // --- KOP SELEKSI TANGGAL ---
            GestureDetector(
              onTap: !isStoreOpen
                  ? null // kalau toko tutup, gak bisa diklik
                  : () {
                      setState(() {
                        _isCalendarOpen = !_isCalendarOpen;
                      });
                    },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: !isStoreOpen ? Colors.grey.shade200 : Colors.white,
                  borderRadius: _isCalendarOpen
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: !isStoreOpen
                              ? Colors.grey
                              : const Color(0xFF0F3773),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDay == null
                              ? "Pilih tanggal"
                              : DateFormat(
                                  'EEEE, d MMMM yyyy',
                                  'id_ID',
                                ).format(_selectedDay!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: !isStoreOpen
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _isCalendarOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            // --- BOX DROPDOWN KALENDER ---
            if (_isCalendarOpen)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(height: 1, color: Colors.black12),
                    TableCalendar(
                      firstDay: DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      ),
                      lastDay: DateTime.now().add(
                        Duration(days: (_storeSettings?.maxBookingDays ?? 7)),
                      ),
                      focusedDay: _focusedDay,

                      enabledDayPredicate: (day) {
                        final today = DateTime.now();
                        final first = DateTime(
                          today.year,
                          today.month,
                          today.day,
                        );
                        final last = first.add(
                          Duration(days: (_storeSettings?.maxBookingDays ?? 7)),
                        );
                        return !day.isBefore(first) && !day.isAfter(last);
                      },

                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) async {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _bookedTimes = []; // reset dulu sambil nunggu load
                        });
                        await _loadBookedTimes(selectedDay);
                        await _loadSchedule(selectedDay);
                      },

                      calendarStyle: const CalendarStyle(
                        disabledTextStyle: TextStyle(color: Colors.grey),
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF1E60FF),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.black12,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isCalendarOpen = false;
                              });
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E60FF),
                            ),
                            onPressed: () async {
                              if (_selectedDay == null) return;

                              await _loadSchedule(_selectedDay!);

                              setState(() {
                                _isCalendarOpen = false;
                                _isTimeBoxVisible = true;
                              });
                            },
                            child: const Text(
                              "Choose Date",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // --- BOX PILIHAN JAM ---
            if (_isTimeBoxVisible)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "JAM TERSEDIA",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDay == null
                          ? ""
                          : DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildStatusIndicator(
                          const Color(0xFFE2F5ED),
                          const Color(0xFF22C55E),
                          "Tersedia",
                        ),
                        _buildStatusIndicator(
                          const Color(0xFFFEE2E2),
                          const Color(0xFFEF4444),
                          "Sudah dipesan",
                        ),
                        _buildStatusIndicator(
                          const Color(0xFFFEF3C7),
                          const Color(0xFFF59E0B),
                          "Reservasi Anda",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availableTimes.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemBuilder: (context, index) {
                        bool isPastTime = false;

                        final time = _availableTimes[index];
                        final now = DateTime.now();
                        final isConfirmed = _confirmedTime == time;
                        final isBooked = _bookedTimes.contains(time);
                        final isDisabled =
                            isBooked || isConfirmed || isPastTime;

                        if (_selectedDay != null &&
                            isSameDay(_selectedDay!, now)) {
                          final timeParts = time.split(':');
                          final bookingTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            int.parse(timeParts[0]),
                            int.parse(timeParts[1]),
                          );

                          final minimumBookingTime = now.add(
                            const Duration(minutes: 30),
                          );
                          isPastTime = bookingTime.isBefore(minimumBookingTime);
                        }

                        // Warna & style berdasarkan kondisi
                        Color bgColor;
                        Color borderColor;
                        Color contentColor;

                        if (isPastTime) {
                          // Waktu sudah lewat → abu-abu
                          bgColor = Colors.grey.shade300;
                          borderColor = Colors.grey.shade400;
                          contentColor = Colors.grey.shade600;
                        } else if (isConfirmed) {
                          // Reservasi milik user sendiri → kuning
                          bgColor = const Color(0xFFFEF3C7);
                          borderColor = const Color(0xFFF59E0B);
                          contentColor = const Color(0xFFF59E0B);
                        } else if (isBooked) {
                          // Sudah dipesan orang lain → merah muda
                          bgColor = const Color(0xFFFEE2E2);
                          borderColor = const Color(0xFFEF4444);
                          contentColor = const Color(0xFFEF4444);
                        } else {
                          // Tersedia → biru
                          bgColor = const Color(0xFFCDE8FC).withOpacity(0.7);
                          borderColor = Colors.transparent;
                          contentColor = const Color(0xFF0F3773);
                        }

                        return GestureDetector(
                          onTap: isDisabled
                              ? null // gak bisa diklik kalau sudah dipesan/konfirmasi
                              : () => _showReservationFormDialog(context, time),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: contentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: contentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  // --- WIDGET PENDUKUNG LAINNYA ---
  Widget _buildStatusIndicator(Color bgColor, Color borderColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showReservationFormDialog(BuildContext context, String time) {
    // Auto-isi dari state yang sudah di-load waktu halaman dibuka
    final nameController = TextEditingController(text: _userName);
    final phoneController = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24),
                    const Text(
                      "Reservasi tempat Anda",
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
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _selectedDay == null
                        ? " "
                        : "${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay!)} · pukul $time",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Nama lengkap",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFCDE8FC),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F3773),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Nomor telepon (WhatsApp)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1B17),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFCDE8FC),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F3773),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3773),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      String inputName = nameController.text.isEmpty
                          ? "No Name"
                          : nameController.text;
                      String inputPhone = phoneController.text.isEmpty
                          ? "No Phone"
                          : phoneController.text;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      );

                      try {
                        String userId = _auth.currentUser?.uid ?? "anonymous";

                        await _reservationService.createReservation(
                          userId: userId,
                          name: inputName,
                          phone: inputPhone,
                          bookingDate: _selectedDay!,
                          bookingTime: time,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          _showSuccessDialog(
                            context,
                            time,
                            inputName,
                            inputPhone,
                          );
                          _showTopSuccessBanner(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal membuat reservasi: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "Konfirmasi reservasi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Batal",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
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

  void _showSuccessDialog(
    BuildContext context,
    String time,
    String name,
    String phone,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F5ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF22C55E),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Reservasi berhasil!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Sampai jumpa di Jamal Barbershop",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCDE8FC),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        "Tanggal",
                        _selectedDay == null
                            ? " "
                            : DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(_selectedDay!),
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRow("Jam", time),
                      const SizedBox(height: 10),
                      _buildSummaryRow("Atas nama", name),
                      const SizedBox(height: 10),
                      _buildSummaryRow("Telepon", phone),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3773),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmedTime = time;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.black45, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showTopSuccessBanner(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Pesanan berhasil cek di tab reservasi saya",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }
}
