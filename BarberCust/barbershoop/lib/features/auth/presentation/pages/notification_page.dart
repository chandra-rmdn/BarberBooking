import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'reservation_page.dart';
import '../../../../service/notification_service.dart';
import '../../../../models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    timeago.setLocaleMessages('id', timeago.IdMessages());
    Future.microtask(() async {
      await _notificationService.markAllAsRead(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotifications(uid),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada notifikasi",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: notifications.length,

            itemBuilder: (context, index) {
              final item = NotificationModel.fromFirestore(
                notifications[index],
              );

              final created = item.createdAt?.toDate();

              return Dismissible(
                key: Key(item.id!),

                direction: DismissDirection.endToStart,

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text("Hapus Notifikasi"),
                        content: const Text(
                          "Apakah Anda yakin ingin menghapus notifikasi ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Hapus"),
                          ),
                        ],
                      );
                    },
                  );
                },

                onDismissed: (_) async {
                  await _notificationService.deleteNotification(item.id!);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Notifikasi berhasil dihapus"),
                    ),
                  );
                },

                child: InkWell(
                borderRadius: BorderRadius.circular(16),

                onTap: () async {
                  await _notificationService.markAsRead(item.id!);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReservationPage()),
                  );
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: item.type == "approved"
                            ? Colors.green.shade100
                            : Colors.red.shade100,

                        child: Icon(
                          item.type == "approved"
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: item.type == "approved"
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              item.body,
                              style: const TextStyle(color: Colors.black54),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              created == null
                                  ? ""
                                  : timeago.format(
                                      item.createdAt!.toDate(),
                                      locale: "id",
                                    ),

                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
