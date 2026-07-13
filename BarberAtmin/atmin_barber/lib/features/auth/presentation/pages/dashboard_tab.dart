import 'package:flutter/material.dart';
import '../../../../models/reservation_model.dart';
import '../../../../services/reservation_service.dart';

// ===========================================================================
// KONTEN TAB 0: DASHBOARD (statistik ringkas)
// ===========================================================================
class DashboardTab extends StatelessWidget {
  const DashboardTab();

  @override
  Widget build(BuildContext context) {
    final ReservationService reservationService = ReservationService();

    return StreamBuilder<List<ReservationModel>>(
      stream: reservationService.getAllReservations(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];

        final total = all.length;
        final waiting = all.where((e) => e.status == "Pending").length;
        final approved = all.where((e) => e.status == "Approved").length;
        final completed = all.where((e) => e.status == "Completed").length;
        final rejected = all.where((e) => e.status == "Rejected").length;
        final cancelled = all
            .where(
              (e) =>
                  e.status == "CancelledByCustomer" ||
                  e.status == "CancelledByAdmin",
            )
            .length;
        final expired = all.where((e) => e.status == "Expired").length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardStatGroup(
                items: [
                  DashboardStatItem(value: total.toString(), label: "Total"),
                  DashboardStatItem(value: waiting.toString(), label: "Waiting"),
                  DashboardStatItem(value: approved.toString(), label: "Approved"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DashboardStatBox(
                      value: completed.toString(),
                      label: "Completed",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatBox(
                      value: rejected.toString(),
                      label: "Rejected",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DashboardStatBox(
                      value: cancelled.toString(),
                      label: "Cancelled",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DashboardStatBox(
                      value: expired.toString(),
                      label: "Expired",
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardStatBox extends StatelessWidget {
  final String value;
  final String label;

  const DashboardStatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F3773), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class DashboardStatItem {
  final String value;
  final String label;
 
  const DashboardStatItem({required this.value, required this.label});
}
 
class DashboardStatGroup extends StatelessWidget {
  final List<DashboardStatItem> items;
 
  const DashboardStatGroup({required this.items});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F3773), width: 1.2),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(items.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color.fromARGB(255, 149, 169, 198),
                indent: 4,
                endIndent: 4,
              );
            }
            final item = items[index ~/ 2];
            return Expanded(
              child: Column(
                children: [
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}