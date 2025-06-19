import 'package:flutter/material.dart';
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
  bool _isPublic = true;
  final List<String> _categories = ['Umum', 'Fisika', 'Matematika', 'Biologi', 'Kimia', 'Sejarah'];
  String? _selectedCategory;
  bool get isEditing => widget.docID != null;
  bool _isPublishing = false; // State untuk loading

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

  // --- FUNGSI PUBLISH DENGAN PENANGANAN ERROR ---
  Future<void> _publishNote() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty || _selectedCategory == null) {
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
      // Jika terjadi error dari Firebase, tampilkan pesannya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      // Pastikan loading berhenti, baik berhasil maupun gagal
      if (mounted) {
        setState(() { _isPublishing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Tulis Catatan", style: TextStyle(color: Colors.black54, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishNote, // Nonaktifkan tombol saat loading
              child: _isPublishing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : Text(isEditing ? 'Perbarui' : 'Terbitkan'),
            ),
          ),
        ],
      ),
      // ... (Body tetap sama) ...
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    const Text('Publik'),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 30),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Judul'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Mulai menulis...'),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}