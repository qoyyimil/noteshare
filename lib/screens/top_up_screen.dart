// lib/screens/top_up_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/widgets/success_dialog.dart'; // Import the new dialog
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // --- DUMMY PAYMENT FUNCTION ---
  Future<void> _handleDummyPayment(int coinsToAdd, int price) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      await _firestoreService.addCoinsToUser(_currentUser!.uid, coinsToAdd);

      if (mounted) {
        // Show the new success dialog
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
                return SuccessDialog(
                    title: "Purchase Successful!",
                    description: "You have successfully added $coinsToAdd coins to your wallet.",
                    buttonText: "Awesome!",
                    onOkPressed: () {
                        Navigator.of(dialogContext).pop(); // Close the dialog
                    },
                );
            }
        ).then((_) {
            Navigator.of(context).pop(); // Go back from TopUpScreen
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
       if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Coin Packages based on our discussion
  final List<Map<String, dynamic>> coinPackages = [
    {'coins': 50, 'price': 8000, 'bonus': 0, 'color': Colors.grey.shade400, 'label': null},
    {'coins': 100, 'price': 16000, 'bonus': 5, 'color': Colors.blue.shade300, 'label': null},
    {'coins': 300, 'price': 49000, 'bonus': 30, 'color': Colors.green.shade400, 'label': 'Popular'},
    {'coins': 500, 'price': 79000, 'bonus': 75, 'color': Colors.purple.shade300, 'label': null},
    {'coins': 1000, 'price': 159000, 'bonus': 200, 'color': Colors.orange.shade400, 'label': 'Best Value'},
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up Coins', style: GoogleFonts.lato()),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text("Processing payment...", style: GoogleFonts.lato()),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: coinPackages.length,
                itemBuilder: (context, index) {
                  final package = coinPackages[index];
                  return _buildCoinPackage(
                    coins: package['coins'],
                    price: package['price'],
                    bonus: package['bonus'],
                    color: package['color'],
                    label: package['label'],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCoinPackage({required int coins, required int price, required int bonus, Color? color, String? label}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleDummyPayment(coins + bonus, price),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, size: 40, color: color ?? Colors.amber),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$coins Coins', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (bonus > 0)
                        Text('+ $bonus Bonus Coins!', style: GoogleFonts.lato(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      
                      const SizedBox(height: 4),
                      Text('Rp ${NumberFormat.decimalPattern('id_ID').format(price)}', style: GoogleFonts.lato(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
            if (label != null)
              Positioned(
                top: 0,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )
                  ),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
