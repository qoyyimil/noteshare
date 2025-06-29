// lib/screens/creator_earnings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:noteshare/widgets/success_dialog.dart';
import 'package:provider/provider.dart';

class CreatorEarningsScreen extends StatefulWidget {
  const CreatorEarningsScreen({super.key});

  @override
  State<CreatorEarningsScreen> createState() => _CreatorEarningsScreenState();
}

class _CreatorEarningsScreenState extends State<CreatorEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Form Controllers
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String? _selectedMethod;
  final List<String> _withdrawalMethods = ['BCA', 'Mandiri', 'GoPay', 'OVO', 'DANA'];

  bool _isWithdrawing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _accountNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdrawal() async {
    if (_currentUser == null) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isWithdrawing = true);

    try {
      final amount = int.parse(_amountController.text);
      await _firestoreService.requestWithdrawal(
        userId: _currentUser!.uid,
        amount: amount,
        method: _selectedMethod!,
        accountNumber: _accountNumberController.text,
      );
      if (mounted) {
        showDialog(
            context: context,
            builder: (ctx) => SuccessDialog(
                  title: "Withdrawal Requested",
                  description: "Your request for $amount coins has been submitted and is now pending review.",
                  buttonText: "Got it!",
                  onOkPressed: () => Navigator.of(ctx).pop(),
                ));
        _amountController.clear();
        _accountNumberController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3B82F6);

    return Scaffold(
      appBar: AppBar(
        title: Text("Creator Earnings", style: GoogleFonts.lato()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          tabs: const [
            Tab(icon: Icon(Icons.download_for_offline), text: "Withdraw"),
            Tab(icon: Icon(Icons.history), text: "History"),
          ],
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildWithdrawTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawTab() {
    if (_currentUser == null) return const Center(child: Text("Please log in."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance
            StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getUserStream(_currentUser!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final coins = (snapshot.data!.data() as Map<String, dynamic>)['coins'] ?? 0;
                return Center(
                  child: Column(
                    children: [
                      Text("Available for Withdrawal", style: GoogleFonts.lato(fontSize: 18, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Text("$coins Coins", style: GoogleFonts.lato(fontSize: 42, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Withdrawal Form
            Text("Withdrawal Details", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedMethod,
              hint: const Text("Select Method"),
              items: _withdrawalMethods.map((method) => DropdownMenuItem(value: method, child: Text(method))).toList(),
              onChanged: (value) => setState(() => _selectedMethod = value),
              validator: (value) => value == null ? 'Please select a method' : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: "Account / E-Wallet Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty ? 'Please enter an account number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Amount of Coins to Withdraw", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Please enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isWithdrawing ? null : _handleWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isWithdrawing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("Request Withdrawal", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_currentUser == null) return const Center(child: Text("Please log in."));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Earnings History", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        _buildHistoryList(_firestoreService.getEarningsHistory(_currentUser!.uid), true),
        const SizedBox(height: 24),
        Text("Withdrawal History", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        _buildHistoryList(_firestoreService.getWithdrawalHistory(_currentUser!.uid), false),
      ],
    );
  }

  Widget _buildHistoryList(Stream<QuerySnapshot> stream, bool isEarning) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("No history found.", style: TextStyle(color: Colors.grey.shade600)),
        ));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final date = timestamp != null ? DateFormat.yMMMd().format(timestamp) : 'N/A';
            
            if(isEarning) {
              return ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                title: Text("Sale: ${data['noteTitle'] ?? 'Untitled'}"),
                subtitle: Text("On $date"),
                trailing: Text("+${data['coinsEarned']} Coins", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              );
            } else {
              return ListTile(
                leading: Icon(Icons.arrow_upward, color: Colors.redAccent.shade100),
                title: Text("Withdrawal to ${data['method']}"),
                subtitle: Text("Status: ${data['status']} - On $date"),
                trailing: Text("-${data['amount']} Coins", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              );
            }
          },
        );
      },
    );
  }
}
