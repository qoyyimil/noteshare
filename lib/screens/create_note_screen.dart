import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class CreateNoteScreen extends StatefulWidget {
  final String? docID;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;
  final bool? initialIsPublic;

  const CreateNoteScreen({
    super.key,
    this.docID,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
    this.initialIsPublic,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color bgColor = Color(0xFFFFFFFF);
  static const Color inputFillColor = Color(0xFFF9FAFB);
  static const Color borderColor = Color(0xFFE5E7EB);

  // --- State for Note Configuration ---
  bool _isPublic = true;
  final List<String> _categories = [
    'General', 'Physics', 'Mathematics', 'Biology', 'Chemistry', 'History'
  ];
  String? _selectedCategory;
  bool get isEditing => widget.docID != null;
  bool _isPublishing = false;

  // --- State for Premium Notes ---
  bool _canPostPremium = false;
  bool _isPremiumNote = false;
  int? _selectedPrice = 10; // Default price
  final List<int> _coinPrices = [10, 25, 50, 100]; // Available prices

  @override
  void initState() {
    super.initState();
    _checkEligibility();
    
    if (isEditing) {
      titleController.text = widget.initialTitle ?? '';
      contentController.text = widget.initialContent ?? '';
      _selectedCategory = widget.initialCategory ?? _categories.first;
      _isPublic = widget.initialIsPublic ?? true;
    } else {
      _selectedCategory = _categories.first;
    }
  }

  void _checkEligibility() async {
    if (_currentUser == null) return;
    final userDoc = await firestoreService.users.doc(_currentUser!.uid).get();
    if (mounted && userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
            _canPostPremium = data['canPostPremium'] ?? false;
        });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _publishNote() async {
    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content must not be empty.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_isPremiumNote && _selectedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a price for the premium note.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final bool finalIsPremium = _isPublic && _isPremiumNote;
      if (isEditing) {
        await firestoreService.updateNote(
          widget.docID!,
          titleController.text,
          contentController.text,
          _selectedCategory!,
          _isPublic,
          isPremium: finalIsPremium,
          coinPrice: finalIsPremium ? (_selectedPrice ?? 0) : 0,
        );
      } else {
        String fullName = '';
        if (_currentUser != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
            final data = userDoc.data();
            if (data != null) {
                fullName = (data as Map<String, dynamic>)['fullName'] ?? _currentUser!.email ?? 'Anonymous';
            } else {
                fullName = _currentUser!.email ?? 'Anonymous';
            }
          } catch (e) {
            fullName = _currentUser!.email ?? 'Anonymous';
          }
        }

        await firestoreService.addNote(
          titleController.text,
          contentController.text,
          _selectedCategory!,
          _isPublic,
          fullName: fullName,
          userId: _currentUser!.uid,
          userEmail: _currentUser!.email,
          isPremium: finalIsPremium,
          coinPrice: finalIsPremium ? (_selectedPrice ?? 0) : 0,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: HomeAppBar(
        searchController: _searchController,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: bgColor, searchKeyword: '', onClearSearch: () {  },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPublishing ? null : _publishNote,
        backgroundColor: _isPublishing ? Colors.grey : primaryBlue,
        icon: _isPublishing
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.send, color: Colors.white),
        label: Text(
          isEditing ? 'Update' : 'Publish',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) {
            return const SearchResultsView();
          }
          return child!;
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfigurationSection(),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleController,
                    maxLines: null,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Your Note Title',
                      hintStyle: GoogleFonts.lora(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                    ),
                    style: GoogleFonts.lora(fontSize: 40, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: null,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Start writing your note here...',
                      hintStyle: GoogleFonts.sourceSerif4(fontSize: 18, color: Colors.grey.shade400),
                    ),
                    style: GoogleFonts.sourceSerif4(fontSize: 18, height: 1.6, color: textColor),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _categories.map((String category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: GoogleFonts.lato())))
                      .toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                ),
              ),
              const SizedBox(width: 16),
              Text('Public', style: GoogleFonts.lato(color: subtleTextColor, fontSize: 16)),
              const SizedBox(width: 8),
              Switch(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                    if (!value) {
                      _isPremiumNote = false;
                    }
                  });
                },
                activeColor: primaryBlue,
              ),
            ],
          ),
          
          if (_canPostPremium) ...[
            const Divider(height: 24),
            // --- PERUBAHAN UTAMA: MENGHAPUS EXPANSIONTILE ---
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_outlined, 
                  color: _isPublic ? Colors.amber.shade700 : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  "Set as Premium Note", 
                  style: GoogleFonts.lato(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: _isPublic ? textColor : Colors.grey,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isPremiumNote,
                  onChanged: _isPublic
                    ? (value) => setState(() => _isPremiumNote = value)
                    : null,
                  activeColor: Colors.amber,
                ),
              ],
            ),
            // Dropdown harga akan muncul jika premium diaktifkan
            if (_isPremiumNote)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: DropdownButtonFormField<int>(
                  value: _selectedPrice,
                  isExpanded: true,
                  items: _coinPrices.map((price) => DropdownMenuItem<int>(
                    value: price, 
                    child: Text("$price Coins", style: GoogleFonts.lato()))
                  ).toList(),
                  onChanged: (value) => setState(() => _selectedPrice = value),
                  decoration: InputDecoration(
                    labelText: "Price",
                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: subtleTextColor, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  ),
                ),
              ),
          ]
        ],
      ),
    );
  }
}