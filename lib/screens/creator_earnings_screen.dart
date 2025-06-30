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

  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  String? _selectedMethod;
  final List<String> _withdrawalMethods = ['BCA', 'Mandiri', 'GoPay', 'OVO', 'DANA'];

  bool _isWithdrawing = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color inputFillColor = Color(0xFFF9FAFB);

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
        setState(() => _selectedMethod = null);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: _searchController,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: inputFillColor,
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
        // MODIFIKASI DIMULAI DI SINI:
        // Mengembalikan Center dan ConstrainedBox dengan maxWidth yang lebih sesuai
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100), // Lebar ideal untuk konten utama
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Padding di sini hanya untuk ruang vertikal, karena horizontal sudah diatur oleh Center
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text("Creator Earnings", style: GoogleFonts.lora(fontSize: 40, fontWeight: FontWeight.bold, color: textColor)),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: primaryBlue,
                  unselectedLabelColor: subtleTextColor,
                  indicatorColor: primaryBlue,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedLabelStyle: GoogleFonts.lato(fontSize: 16),
                  tabs: const [
                    Tab(text: "Withdraw"),
                    Tab(text: "History"),
                  ],
                ),
                const Divider(height: 1, color: borderColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWithdrawTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawTab() {
    if (_currentUser == null) return const Center(child: Text("Please log in."));

    // Form penarikan tidak perlu membentang selebar 1100px, jadi kita batasi lebarnya di sini
    // agar lebih mudah dibaca dan diisi.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _firestoreService.getUserStream(_currentUser!.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final coins = (snapshot.data!.data() as Map<String, dynamic>)['coins'] ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Available for Withdrawal",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(fontSize: 18, color: Colors.blue.shade800)),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        Text("1 Coin = Rp 100",
                            style: GoogleFonts.lato(fontSize: 14, color: Colors.blue.shade700)),
                      ],
                    ),
                  );
                },
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Withdrawal Details", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedMethod,
                      hint: Text("Select Method", style: GoogleFonts.lato()),
                      style: GoogleFonts.lato(color: textColor, fontSize: 16),
                      items: _withdrawalMethods.map((method) =>
                          DropdownMenuItem(value: method, child: Text(method))).toList(),
                      onChanged: (value) => setState(() => _selectedMethod = value),
                      validator: (value) => value == null ? 'Please select a method' : null,
                      decoration: _inputDecoration(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      style: GoogleFonts.lato(fontSize: 16),
                      decoration: _inputDecoration(labelText: "Account / E-Wallet Number"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter an account number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      style: GoogleFonts.lato(fontSize: 16),
                      decoration: _inputDecoration(labelText: "Amount of Coins to Withdraw"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter an amount';
                        if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Please enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isWithdrawing ? null : _handleWithdrawal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isWithdrawing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                            : Text("Request Withdrawal", style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
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
  }

  Widget _buildHistoryTab() {
    if (_currentUser == null) return const Center(child: Text("Please log in."));
    
    // Gunakan Row untuk membuat tata letak 2 kolom
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kolom Pertama: Earnings History
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Earnings History", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Expanded di dalam Column agar ListView mengisi ruang yang tersedia
                Expanded(
                  child: _buildHistoryList(_firestoreService.getEarningsHistory(_currentUser!.uid), true),
                ),
              ],
            ),
          ),
        ),
        // Garis pemisah vertikal antar kolom
        const VerticalDivider(width: 1, thickness: 1, color: borderColor),
        // Kolom Kedua: Withdrawal History
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Withdrawal History", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildHistoryList(_firestoreService.getWithdrawalHistory(_currentUser!.uid), false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(Stream<QuerySnapshot> stream, bool isEarning) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text("No history found.", style: GoogleFonts.lato(color: Colors.grey.shade600)),
        ));
        return ListView.separated(
          // shrinkWrap: true,
          // physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final date = timestamp != null ? DateFormat('d MMM yy, HH:mm').format(timestamp) : 'N/A';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              leading: Icon(
                isEarning ? Icons.arrow_downward : Icons.arrow_upward,
                color: isEarning ? Colors.green : Colors.red,
              ),
              title: Text(
                isEarning ? "From: ${data['noteTitle'] ?? 'Untitled'}" : "To: ${data['method']}",
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(isEarning ? "On $date" : "Status: ${data['status']} - On $date", style: GoogleFonts.lato(fontSize: 12)),
              trailing: Text(
                isEarning ? "+${data['coinsEarned']} Coins" : "-${data['amount']} Coins",
                style: GoogleFonts.lato(color: isEarning ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration({String? labelText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.lato(color: subtleTextColor),
      hintStyle: GoogleFonts.lato(color: subtleTextColor),
      filled: true,
      fillColor: inputFillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }
}