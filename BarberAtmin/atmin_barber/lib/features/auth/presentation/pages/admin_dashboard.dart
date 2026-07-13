import 'package:flutter/material.dart';
import 'dashboard_tab.dart';
import 'bookings_tab.dart';
import 'schedules_tab.dart';
import 'settings_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _navIndex = 0;

  static const List<String> _titles = [
    "Dashboard",
    "Bookings",
    "Schedule",
    "Settings",
  ];

  static const List<Widget> _pages = [
    DashboardTab(),
    BookingsTab(),
    SchedulesTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          _titles[_navIndex],
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
      body: IndexedStack(index: _navIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _buildNavItem(0, Icons.grid_view_rounded, "Dashboard"),
              _buildNavItem(1, Icons.description_outlined, "Bookings"),
              _buildNavItem(2, Icons.calendar_month_outlined, "Schedule"),
              _buildNavItem(3, Icons.settings_outlined, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _navIndex == index;
    final Color color = isActive
        ? const Color(0xFF0F3773)
        : Colors.black38;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _navIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}