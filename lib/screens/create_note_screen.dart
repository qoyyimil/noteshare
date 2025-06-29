// lib/screens/create_note_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    _checkEligibility(); // Check if the user can post premium notes
    
    _searchController.addListener(() {
      setState(() {}); // Update UI when search text changes
    });

    if (isEditing) {
      titleController.text = widget.initialTitle ?? '';
      contentController.text = widget.initialContent ?? '';
      _selectedCategory = widget.initialCategory ?? _categories.first;
      _isPublic = widget.initialIsPublic ?? true;
      // Note: You might want to fetch and set the initial premium status/price here if editing.
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

  void _onClearSearch() {
    _searchController.clear();
  }

  void _onMenuItemSelected(String value, BuildContext context) {
    switch (value) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature not available yet.')),
        );
        break;
      case 'library':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Library feature not available yet.')),
        );
        break;
      case 'notes':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('My Notes feature not available yet.')),
        );
        break;
      case 'logout':
        Navigator.pop(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('The feature "$value" is not available yet.')),
        );
        break;
    }
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
      if (isEditing) {
        await firestoreService.updateNote(
          widget.docID!,
          titleController.text,
          contentController.text,
          _selectedCategory!,
          _isPublic,
          isPremium: _isPremiumNote,
          coinPrice: _selectedPrice ?? 0,
        );
      } else {
        String fullName = '';
        if (_currentUser != null) {
          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
            fullName = userDoc.data()?['fullName'] ?? _currentUser!.email ?? 'Anonymous';
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
          isPremium: _isPremiumNote,
          coinPrice: _selectedPrice ?? 0,
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
        searchKeyword: _searchController.text,
        onClearSearch: _onClearSearch,
        currentUser: _currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: bgColor,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPublishing ? null : _publishNote,
        backgroundColor: _isPublishing ? Colors.grey : primaryBlue,
        icon: _isPublishing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white),
        label: Text(isEditing ? 'Update' : 'Publish', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfigurationSection(),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Your Note Title',
                    hintStyle: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                  ),
                  style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start writing your note here...',
                    hintStyle: GoogleFonts.sourceSerif4(fontSize: 18, color: Colors.grey.shade400),
                  ),
                  style: GoogleFonts.sourceSerif4(fontSize: 18, height: 1.6, color: textColor),
                  maxLines: null,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildConfigurationSection() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories
                        .map((String category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category, style: GoogleFonts.lato())))
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedCategory = newValue),
                    icon: const Icon(Icons.arrow_drop_down, color: subtleTextColor),
                    dropdownColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Text('Public', style: GoogleFonts.lato(color: subtleTextColor)),
            const SizedBox(width: 8),
            Switch(
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              activeColor: primaryBlue,
            ),
          ],
        ),
        if (_canPostPremium) ...[
          const Divider(height: 24),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.workspace_premium_outlined, color: Colors.amber),
              const SizedBox(width: 8),
              Text("Set as Premium Note", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: _isPremiumNote,
                onChanged: (value) => setState(() => _isPremiumNote = value),
                activeColor: Colors.amber,
              ),
            ],
          ),
          if (_isPremiumNote)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
              child: Container(
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
                child: DropdownButtonFormField<int>(
                  value: _selectedPrice,
                  items: _coinPrices
                      .map((price) => DropdownMenuItem<int>(
                          value: price, child: Text("$price Coins")))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPrice = value),
                  // --- PERBAIKAN DI SINI ---
                  dropdownColor: Colors.white, // Menetapkan warna background menu saat dibuka
                  decoration: InputDecoration(
                    labelText: "Note Price",
                    labelStyle: TextStyle(color: textColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            )
        ]
      ],
    );
  }
}
