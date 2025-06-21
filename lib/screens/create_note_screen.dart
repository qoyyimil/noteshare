import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';

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
  
  // -- UI Colors & Styles --
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color textColor = Color(0xFF1F2937);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color bgColor = Color(0xFFFFFFFF);

  bool _isPublic = true;
  final List<String> _categories = ['Umum', 'Fisika', 'Matematika', 'Biologi', 'Kimia', 'Sejarah'];
  String? _selectedCategory;
  bool get isEditing => widget.docID != null;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      titleController.text = widget.initialTitle ?? '';
      contentController.text = widget.initialContent ?? '';
      _selectedCategory = widget.initialCategory ?? _categories.first;
      _isPublic = widget.initialIsPublic ?? true;
    } else {
      _selectedCategory = _categories.first;
    }
  }

  Future<void> _publishNote() async {
    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan konten tidak boleh kosong.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isPublishing = true; });

    try {
      if (isEditing) {
        await firestoreService.updateNote(widget.docID!, titleController.text, contentController.text, _selectedCategory!, _isPublic);
      } else {
        await firestoreService.addNote(titleController.text, contentController.text, _selectedCategory!, _isPublic);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isPublishing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: subtleTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Edit Catatan" : "Tulis Catatan Baru",
          style: GoogleFonts.lato(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isPublishing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : Text(isEditing ? 'Perbarui' : 'Terbitkan'),
            ),
          ),
        ],
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
                // Title TextField
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Judul Catatan Anda...',
                    hintStyle: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                  ),
                  style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                // Content TextField
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Mulai menulis di sini...',
                    hintStyle: GoogleFonts.sourceSerif4(fontSize: 18, color: Colors.grey.shade400),
                  ),
                  style: GoogleFonts.sourceSerif4(fontSize: 18, height: 1.6, color: textColor),
                  maxLines: null,
                ),
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
        border: Border.all(color: Colors.grey.shade200)
      ),
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
          Text('Publik', style: GoogleFonts.lato(color: subtleTextColor)),
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
