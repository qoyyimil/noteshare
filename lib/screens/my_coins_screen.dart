import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:noteshare/widgets/success_dialog.dart';
import 'package:provider/provider.dart';

class MyCoinsScreen extends StatefulWidget {
  const MyCoinsScreen({super.key});

  @override
  State<MyCoinsScreen> createState() => _MyCoinsScreenState();
}

class _MyCoinsScreenState extends State<MyCoinsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _handleDummyPayment(int coinsToAdd) async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      await _firestoreService.addCoinsToUser(_currentUser!.uid, coinsToAdd);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => SuccessDialog(
            title: "Purchase Successful!",
            description: "You have successfully added $coinsToAdd coins to your wallet.",
            buttonText: "Awesome!",
            onOkPressed: () => Navigator.of(dialogContext).pop(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<Map<String, dynamic>> coinPackages = [
    {'coins': 50, 'price': 8000, 'bonus': 0, 'color': Colors.grey.shade400, 'label': null},
    {'coins': 100, 'price': 16000, 'bonus': 5, 'color': Colors.blue.shade300, 'label': null},
    {'coins': 300, 'price': 49000, 'bonus': 30, 'color': Colors.green.shade400, 'label': 'Popular'},
    {'coins': 500, 'price': 79000, 'bonus': 75, 'color': Colors.purple.shade300, 'label': null},
    {'coins': 1000, 'price': 159000, 'bonus': 200, 'color': Colors.orange.shade400, 'label': 'Best Value'},
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3B82F6);
    const Color subtleTextColor = Color(0xFF6B7280);
    const Color sidebarBgColor = Color(0xFFF9FAFB);

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }
    
    return Scaffold(
      appBar: HomeAppBar(
        searchController: TextEditingController(),
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
        searchKeyword: '',
        onClearSearch: () {},
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Processing..."),
                  ],
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: _firestoreService.getUserStream(_currentUser!.uid),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              final int coins = userData['coins'] ?? 0;
                              return _buildBalanceDisplay(coins, primaryBlue);
                            },
                          ),
                        ),
                        const VerticalDivider(
                          color: Color(0xFFE5E7EB),
                          thickness: 1,
                          width: 64,  
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Out of Coins? Choose a Package",
                                style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Use coins to purchase paid note content",
                                style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.normal, color: subtleTextColor),
                              ),
                              const SizedBox(height: 20),
                              _buildTopUpGrid(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceDisplay(int coins, Color primaryBlue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_balance_wallet_outlined, size: 80, color: primaryBlue.withOpacity(0.8)),
        const SizedBox(height: 24),
        Text("Your Current Balance", style: GoogleFonts.lato(fontSize: 18, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NumberFormat.decimalPattern('en_US').format(coins),
              style: GoogleFonts.lato(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.monetization_on, color: Colors.amber.shade600, size: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildTopUpGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: coinPackages.length,
      itemBuilder: (context, index) {
        final package = coinPackages[index];
        return _buildCoinCard(
          coins: package['coins'],
          price: package['price'],
          bonus: package['bonus'],
          color: package['color'],
          label: package['label'],
        );
      },
    );
  }

  Widget _buildCoinCard({
    required int coins,
    required int price,
    required int bonus,
    Color? color,
    String? label,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _handleDummyPayment(coins + bonus),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    Icon(Icons.monetization_on, size: 32, color: color ?? Colors.amber),
                    const SizedBox(height: 12),
                    Text('$coins Coins', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (bonus > 0)
                      Text('+ $bonus Bonus!', style: GoogleFonts.lato(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Rp ${NumberFormat.decimalPattern('id_ID').format(price)}', style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            if (label != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: label == 'Popular' ? Colors.orangeAccent : Colors.redAccent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    )
                  ),
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}