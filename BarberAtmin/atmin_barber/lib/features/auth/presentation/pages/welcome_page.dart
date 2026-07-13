import 'dart:async'; // <--- 1. INI DISEDIAKAN BUAT TIMER
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // <--- 2. BIAR BISA PINDAH KE LOGIN PAGE
import 'admin_dashboard.dart';

// SEKARANG SUDAH JADI STATEFUL WIDGET
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () async {
      final user = await FirebaseAuth.instance.authStateChanges().first;

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCDE8FC),
      body: Stack(
        children: [
          // BACKGROUND PUTIH DENGAN LENGKUNGAN DI BAWAH
          ClipPath(
            clipper: BottomCurveClipper(),
            child: Container(
              color: Colors.white,
              height: MediaQuery.of(context).size.height * 0.65,
            ),
          ),

          // KONTEN UTAMA (LOGO & TEXT)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // AREA LOGO & NAMA (Bagian Putih)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.content_cut,
                          size: 60,
                          color: Color(0xFF1E293B),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.format_align_left,
                          size: 60,
                          color: Color(0xFF1E3A8A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Jamal ',
                            style: TextStyle(color: Color(0xFF0F172A)),
                          ),
                          TextSpan(
                            text: 'Barbershop',
                            style: TextStyle(
                              color: Color(0xFF4682B4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // AREA SLOGAN (Bagian Biru Muda)
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 60.0,
                    left: 32.0,
                    right: 32.0,
                  ),
                  child: Text(
                    "Styles that fit your lifestyle.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
}

// CUSTOM CLIPPER
class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 60);

    var firstControlPoint = Offset(size.width / 2, size.height + 50);
    var firstEndPoint = Offset(size.width, size.height - 60);

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
