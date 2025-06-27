import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  bool _isPublic = true;
  final List<String> _categories = [
    'General',
    'Physics',
    'Mathematics',
    'Biology',
    'Chemistry',
    'History'
  ];
  String? _selectedCategory;
  bool get isEditing => widget.docID != null;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update UI when search text changes
    });

    if (isEditing) {
      titleController.text = widget.initialTitle ?? '';
      contentController.text = widget.initialContent ?? '';
      _selectedCategory = widget.initialCategory ?? _categories.first;
      _isPublic = widget.initialIsPublic ?? true;
    } else {
      _selectedCategory = _categories.first;
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
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('The title and content must not be empty..'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      if (isEditing) {
        await firestoreService.updateNote(widget.docID!, titleController.text,
            contentController.text, _selectedCategory!, _isPublic);
      } else {
        await firestoreService.addNote(titleController.text,
            contentController.text, _selectedCategory!, _isPublic);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to save: ${e.toString()}"),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
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
        foregroundColor: Colors.white,
        elevation: 6,
        icon: _isPublishing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          isEditing ? 'Update' : 'Publish',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfigurationSection(),
                const SizedBox(height: 16),
                // Title TextField
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Your Note Title',
                    hintStyle: GoogleFonts.lora(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  style: GoogleFonts.lora(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Content TextField
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Start writing your note here...',
                    hintStyle: GoogleFonts.sourceSerif4(
                      fontSize: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  style: GoogleFonts.sourceSerif4(
                    fontSize: 18,
                    height: 1.6,
                    color: textColor,
                  ),
                  maxLines: null,
                ),
                // Add some bottom padding to prevent content being hidden behind FAB
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: GoogleFonts.lato()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                icon: const Icon(Icons.arrow_drop_down, color: subtleTextColor),
              ),
            ),
          ),
          const VerticalDivider(width: 20),
          Text('Public', style: GoogleFonts.lato(color: subtleTextColor)),
          const SizedBox(width: 8),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeColor: primaryBlue,
          ),
        ],
      ),
    );
  }
}
