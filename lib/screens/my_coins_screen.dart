// lib/screens/my_coins_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/screens/top_up_screen.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';

class MyCoinsScreen extends StatelessWidget {
  const MyCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your coins.")),
      );
    }
    
    // Theme colors
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color subtleTextColor = Color(0xFF6B7280);
    const Color sidebarBgColor = Color(0xFFF9FAFB);

    return Scaffold(
      appBar: HomeAppBar(
        searchController: TextEditingController(),
        searchKeyword: '',
        onClearSearch: () {},
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: firestoreService.getUserStream(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("Could not load user data.");
              }
              
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final int coins = userData['coins'] ?? 0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 100, color: primaryBlue.withOpacity(0.8)),
                  const SizedBox(height: 24),
                  Text("Your Current Balance",
                      style: GoogleFonts.lato(
                          fontSize: 22, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        NumberFormat.decimalPattern('en_US').format(coins),
                        style: GoogleFonts.lato(
                            fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                       Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 40),
                    ],
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TopUpScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle),
                    label: const Text("Top Up Coins"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)
                      )
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
