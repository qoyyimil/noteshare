import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:noteshare/screens/home_screen.dart';
import 'package:noteshare/screens/landing_screen.dart'; // Pastikan Anda sudah mengimpor landing screen

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Cek jika pengguna sudah login
          if (snapshot.hasData) {
            // Jika sudah, langsung ke halaman utama (Home)
            return const HomeScreen();
          } 
          // Jika pengguna BELUM login
          else {
            // Tampilkan Landing Page, BUKAN halaman login/register
            return const LandingScreen(); 
          }
        },
      ),
    );
  }
}