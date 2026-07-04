import 'package:flutter/material.dart';
import 'features/auth/presentation/pages/welcome_page.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jamal Barbershop',
      debugShowCheckedModeBanner: false, // Menghilangkan banner debug merah di kanan atas
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const WelcomePage(), 
    );
  }
}