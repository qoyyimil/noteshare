// lib/screens/creator_earnings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/success_dialog.dart';

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
        setState(() {
          _selectedMethod = null;
        });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Creator Earnings", style: GoogleFonts.lato()),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: "Withdraw"),
            Tab(icon: Icon(Icons.history), text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWithdrawTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // --- UI WIDGET TELAH DIPERBAIKI DI SINI ---
  Widget _buildWithdrawTab() {
    if (_currentUser == null) return const Center(child: Text("Please log in."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance Card
            StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getUserStream(_currentUser!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final coins = (snapshot.data!.data() as Map<String, dynamic>)['coins'] ?? 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text("Available for Withdrawal",
                          style: GoogleFonts.lato(
                              fontSize: 18, color: Colors.blue.shade800)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monetization_on, color: Colors.amber.shade700, size: 40),
                          const SizedBox(width: 8),
                          Text(NumberFormat.decimalPattern('id_ID').format(coins),
                              style: GoogleFonts.lato(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Withdrawal Form
            Text("Withdrawal Details",
                style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- PERBAIKAN UI DROPDOWN DI SINI ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedMethod,
                hint: const Text("Select Method"),
                items: _withdrawalMethods
                    .map((method) =>
                        DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMethod = value),
                validator: (value) =>
                    value == null ? 'Please select a method' : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none, // Sembunyikan border asli
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                  labelText: "Account / E-Wallet Number",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter an account number'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                  labelText: "Amount of Coins to Withdraw",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter an amount';
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isWithdrawing ? null : _handleWithdrawal,
                icon: _isWithdrawing
                    ? Container()
                    : const Icon(Icons.send_outlined),
                label: _isWithdrawing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text("Request Withdrawal", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text("Earnings History", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildHistoryList(_firestoreService.getEarningsHistory(_currentUser!.uid), true),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text("Withdrawal History", style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildHistoryList(_firestoreService.getWithdrawalHistory(_currentUser!.uid), false),
      ],
    );
  }

  Widget _buildHistoryList(Stream<QuerySnapshot> stream, bool isEarning) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("No history found.",
                style: TextStyle(color: Colors.grey.shade600)),
          ));
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final date =
                timestamp != null ? DateFormat.yMMMd().format(timestamp) : 'N/A';

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(
                  isEarning ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isEarning ? Colors.green : Colors.redAccent.shade100,
                ),
                title: Text(
                  isEarning
                      ? "Sale: ${data['noteTitle'] ?? 'Untitled'}"
                      : "Withdrawal to ${data['method']}",
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isEarning ? "On $date" : "Status: ${data['status']} - On $date",
                  style: GoogleFonts.lato(),
                ),
                trailing: Text(
                  isEarning
                      ? "+${data['coinsEarned']} Coins"
                      : "-${data['amount']} Coins",
                  style: TextStyle(
                    color: isEarning ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
