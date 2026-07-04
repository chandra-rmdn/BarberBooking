import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isNotificationOn = true;
  bool _isLoading = true;

  String _name = '';
  String _phone = '';
  String _email = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _name = doc.data()?['name'] ?? '';
          _phone = doc.data()?['phone'] ?? '';
          _email = doc.data()?['email'] ?? _auth.currentUser?.email ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Profil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Nomor Telepon",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3773),
              ),
              onPressed: () async {
                final uid = _auth.currentUser?.uid;
                if (uid == null) return;

                final newName = nameController.text.trim();
                final newPhone = phoneController.text.trim();

                await _firestore.collection('users').doc(uid).update({
                  'name': newName,
                  'phone': newPhone,
                });

                // Update display name di Firebase Auth juga
                await _auth.currentUser?.updateDisplayName(newName);

                if (mounted) {
                  setState(() {
                    _name = newName;
                    _phone = newPhone;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profil berhasil diperbarui")),
                  );
                }
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCDE8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F3773)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3773),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- KARTU USER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F3773)))
                    : Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF0F3773), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name.isEmpty ? "-" : _name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _phone.isEmpty ? "-" : _phone,
                                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _email,
                                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Color(0xFF0F172A)),
                            onPressed: _showEditDialog,
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // --- PREFERENCES ---
              const Text(
                "PREFERENCES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.notifications_none, color: Color(0xFF0F3773)),
                        SizedBox(width: 12),
                        Text(
                          "Push Notifications",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isNotificationOn,
                      activeColor: const Color(0xFF0F3773),
                      onChanged: (value) => setState(() => _isNotificationOn = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- SUPPORT ---
              const Text(
                "SUPPORT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.description_outlined,
                      title: "Privacy Policy",
                      onTap: () => _bukaHalamanDetail(context, "Privacy Policy"),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.black12),
                    _buildMenuTile(
                      icon: Icons.help_outline,
                      title: "Help & FAQ",
                      onTap: () => _bukaHalamanDetail(context, "Help & FAQ"),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.black12),
                    _buildMenuTile(
                      icon: Icons.info_outline,
                      title: "About Bahlil Barber",
                      onTap: () => _bukaHalamanDetail(context, "About Bahlil Barber"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- TOMBOL LOGOUT ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final konfirmasi = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Anda yakin ingin logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Logout", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (konfirmasi != true) return;
                    if (!mounted) return;

                    await FirebaseAuth.instance.signOut();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 211, 211),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(
                        color: Color.fromARGB(255, 255, 148, 148),
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 255, 102, 102),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F3773)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _bukaHalamanDetail(BuildContext context, String namaMenu) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(namaMenu),
            backgroundColor: const Color(0xFF0F3773),
            foregroundColor: Colors.white,
          ),
          body: Center(child: Text("Ini adalah isi dari halaman $namaMenu")),
        ),
      ),
    );
  }
}