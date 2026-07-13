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
import 'dart:async';

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
  List<String> _bookedTimes = [];

  StreamSubscription<QuerySnapshot>? _bookingListener;
  StreamSubscription<DocumentSnapshot>? _storeListener;
  StreamSubscription<DocumentSnapshot>? _defaultScheduleListener;
  StreamSubscription<DocumentSnapshot>? _specialScheduleListener;

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
    _listenBookedTimes(today);
    _listenSchedule(today);
    _loadSchedule(today);
  }

  @override
  void dispose() {
    _bookingListener?.cancel();
    _storeListener?.cancel();
    _defaultScheduleListener?.cancel();
    _specialScheduleListener?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    print("UID: $uid"); // tambah ini
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      print("Doc exists: ${doc.exists}"); // tambah ini
      print("Doc data: ${doc.data()}"); // tambah ini
      if (doc.exists && mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
          _userPhone = doc.data()?['phone'] ?? '';
        });
      }
    } catch (e) {
      print("Error loadUserData: $e"); // tambah ini
    }
  }

  void _listenBookedTimes(DateTime date) {
    _bookingListener?.cancel();

    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    _bookingListener = _firestore
        .collection('reservations')
        .where('bookingDate', isEqualTo: formattedDate)
        .where('status', whereIn: ['Pending', 'Approved'])
        .snapshots()
        .listen((snapshot) {
          print("DOC COUNT = ${snapshot.docs.length}");

          for (final doc in snapshot.docs) {
            print(doc.data());
          }

          if (!mounted) return;

          setState(() {
            _bookedTimes = snapshot.docs
                .map((doc) => doc['bookingTime'] as String)
                .toList();
          });
        });
  }

  void _listenSchedule(DateTime date) {
    _storeListener?.cancel();
    _defaultScheduleListener?.cancel();
    _specialScheduleListener?.cancel();

    final weekdayName = DateFormat('EEEE', 'en_US').format(date).toLowerCase();

    debugPrint("weekday listener = $weekdayName");

    final specialId =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    _storeListener = FirebaseFirestore.instance
        .collection("store_settings")
        .doc("main")
        .snapshots()
        .listen((_) async {
          if (!mounted) return;

          if (_selectedDay != null) {
            await _loadSchedule(_selectedDay!);
          }
        });

    _defaultScheduleListener = FirebaseFirestore.instance
        .collection("default_schedule")
        .doc(weekdayName)
        .snapshots()
        .listen((event) async {

          if (!mounted) return;

          if (_selectedDay != null) {
            await _loadSchedule(_selectedDay!);
          }
        });

    _specialScheduleListener = FirebaseFirestore.instance
        .collection("special_schedule")
        .doc(specialId)
        .snapshots()
        .listen((_) async {
          if (!mounted) return;

          if (_selectedDay != null) {
            await _loadSchedule(_selectedDay!);
          }
        });
  }

  Future<void> _loadSchedule(DateTime date) async {
    final settings = await _scheduleService.getStoreSettings();
    final schedule = await _scheduleService.getSchedule(date);

    List<String> slots = [];

    if (schedule != null && schedule.isOpen) {
      slots = _scheduleService
          .generateSlots(
            openMinutes: schedule.openMinutes,
            closeMinutes: schedule.closeMinutes,
            slotDurationMinutes: settings.slotDurationMinutes,
          )
          .map((e) => _scheduleService.formatMinutes(e))
          .toList();
    }

    setState(() {
      _storeSettings = settings;
      _currentSchedule = schedule;
      _availableTimes = slots;
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
          (snapshot) => snapshot.docs.where((doc) {
            final status = doc.data()['status'] ?? '';

            return status == 'Pending' || status == 'Approved';
          }).length,
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
        backgroundColor: const Color(0xFFF4F6FA),
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5E9F0),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF0F3773),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Halo, Selamat Datang!",
                                style: TextStyle(
                                  fontSize: 13,
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // 🌟 NAVIGASI ICON BELL + GEAR KE PROFILE PAGE
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF0F172A),
                            size: 26,
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF0F172A),
                              size: 26,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- CARD BARBERSHOP + TOMBOL BOOKING ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Jamal Barbershop",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Haircut, styling, dan grooming profesional.",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentTabIndex = 0;
                            });
                            DefaultTabController.of(context).animateTo(0);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3773),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFF5A623),
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              "Booking Sekarang!",
                              style: TextStyle(
                                color: Color(0xFFF5A623),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- TAB MENU ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 6,
                    ),
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECF2),
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
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: const Color(0xFF0F172A),
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
                                        color: Color(0xFFF5A623),
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
        if (_storeSettings == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final bool isGlobalStoreOpen = _storeSettings?.isStoreOpen ?? false;
        final bool isSelectedDateOpen =
            _currentSchedule != null && _currentSchedule!.isOpen;

        // Kalau toko baru tutup, reset semua state pilihan biar jam gak bisa diklik
        if (!isGlobalStoreOpen && (_isCalendarOpen || _isTimeBoxVisible)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isCalendarOpen = false;
                _isTimeBoxVisible = false;
              });
            }
          });
        }

        return Column(
          children: [
            // --- BANNER TOKO TUTUP ---
            if (!isGlobalStoreOpen)
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

            // --- LABEL BULAN ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_focusedDay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- BARIS KARTU TANGGAL (Sen - Min) ---
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (_storeSettings?.maxBookingDays ?? 7) + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final today = DateTime.now();
                  final day = DateTime(
                    today.year,
                    today.month,
                    today.day,
                  ).add(Duration(days: index));

                  final isSelected = isSameDay(_selectedDay, day);

                  return GestureDetector(
                    onTap: !isGlobalStoreOpen
                        ? null
                        : () async {
                            setState(() {
                              _selectedDay = day;
                              _focusedDay = day;
                              _bookedTimes = [];
                              _isTimeBoxVisible = true;
                            });
                            _listenBookedTimes(day);
                            _listenSchedule(day);
                            await _loadSchedule(day);
                          },
                    child: Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF5A623)
                              : const Color(0xFFE5E9F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', 'id_ID').format(day),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? const Color(0xFFF5A623)
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${day.day}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? const Color(0xFFF5A623)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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

                    if (isGlobalStoreOpen &&
                        _selectedDay != null &&
                        !isSelectedDateOpen)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Barbershop tutup pada tanggal yang dipilih.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

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
                          // Tersedia → outline navy
                          bgColor = Colors.white;
                          borderColor = const Color(0xFF0F3773);
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
