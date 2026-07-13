import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/schedule_model.dart';
import '../../../../models/store_settings_model.dart';
import '../../../../services/reservation_service.dart';
import '../../../../services/schedule_sevice.dart';

// ===========================================================================
// KONTEN TAB 2: SCHEDULES (sekarang nyambung ke Firestore koleksi 'store_settings')
// ===========================================================================
class SchedulesTab extends StatefulWidget {
  const SchedulesTab();

  @override
  State<SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends State<SchedulesTab> {
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
    final bool isOpen = _settings!.isStoreOpen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Store Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Store Open",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCBD3E1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (isOpen) return;
                    final newSettings = _settings!.copyWith(isStoreOpen: true);
                    await _scheduleService.updateStoreSettings(newSettings);
                    setState(() {
                      _settings = newSettings;
                    });
                  },
                  child: Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen ? const Color(0xFF0F3773) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "OPEN",
                      style: TextStyle(
                        color: isOpen ? const Color(0xFFF5A623) : Colors.black26,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!isOpen) return;
                    final newSettings = _settings!.copyWith(isStoreOpen: false);
                    await _scheduleService.updateStoreSettings(newSettings);
                    setState(() {
                      _settings = newSettings;
                    });
                  },
                  child: Container(
                    width: 74,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: !isOpen ? const Color(0xFF0F3773) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "CLOSED",
                      style: TextStyle(
                        color: !isOpen ? const Color(0xFFF5A623) : Colors.black26,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final Map<String, String> dayLabels = const {
      "monday": "Senin",
      "tuesday": "Selasa",
      "wednesday": "Rabu",
      "thursday": "Kamis",
      "friday": "Jumat",
      "saturday": "Sabtu",
      "sunday": "Minggu",
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Weekly Schedule",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9F0)),
          ),
          child: Column(
            children: List.generate(_days.length, (index) {
              final day = _days[index];
              final schedule = _defaultSchedules[day];

              if (schedule == null) {
                return const SizedBox();
              }

              final hours =
                  "${_formatMinutes(schedule.openMinutes)} - ${_formatMinutes(schedule.closeMinutes)}";

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayLabels[day] ?? day,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              schedule.isOpen ? hours : "Closed",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showEditScheduleDialog(day),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF0F3773),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != _days.length - 1)
                    const Divider(height: 1, color: Color(0xFFE5E9F0)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialSchedule() {
    return Container(
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
              const Text(
                "Special Schedule",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: _showAddSpecialScheduleDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3773),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFFF5A623)),
                      SizedBox(width: 4),
                      Text(
                        "Tambah",
                        style: TextStyle(
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E9F0)),
                  ),
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Text(
                            DateFormat(
                              "EEEE, d MMM yyyy",
                              "id_ID",
                            ).format(DateTime.parse(date)),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      if ((item["reason"] ?? "").toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item["reason"],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOpen
                                ? const Color(0xFF0F3773)
                                : const Color(0xFFCBD3E1),
                          ),
                        ),
                        child: Text(
                          isOpen ? "$open - $close" : "Closed",
                          style: TextStyle(
                            color: isOpen
                                ? const Color(0xFF0F3773)
                                : Colors.black45,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF0F3773),
                              size: 20,
                            ),
                            onPressed: () {
                              _showEditSpecialScheduleDialog(item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
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