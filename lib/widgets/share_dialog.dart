import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noteshare/services/firestore_service.dart';

class ShareDialog extends StatefulWidget {
  final String noteId; // <-- Butuh noteId untuk proses invite
  final String noteTitle;
  final String shareUrl;
  final bool isOwner; // <-- Parameter kunci untuk menentukan tampilan

  const ShareDialog({
    super.key,
    required this.noteId,
    required this.noteTitle,
    required this.shareUrl,
    required this.isOwner,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final TextEditingController _emailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Fungsi untuk menangani undangan
  Future<void> _handleInvite() async {
    if (_emailController.text.trim().isEmpty) return;
    
    setState(() { _isLoading = true; });

    final String email = _emailController.text.trim();
    final String result = await _firestoreService.inviteUserToNote(
      noteId: widget.noteId, 
      email: email
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      if (result.startsWith("Success")) {
        _emailController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: 450,
        child: _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share "${widget.noteTitle}"',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  
                  // Menampilkan UI berbeda berdasarkan kepemilikan
                  if (widget.isOwner)
                    _buildOwnerView(context) // Tampilan untuk pemilik
                  else
                    _buildPublicView(), // Tampilan untuk pembaca

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_all_outlined, size: 18),
                        label: const Text('Copy Link'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.shareUrl)).then((_) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard!')),
                            );
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  // Widget untuk tampilan PEMILIK catatan
  Widget _buildOwnerView(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Add user email to invite',
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleInvite,
            )
          ),
        ),
        const SizedBox(height: 20),
        if (currentUser != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(currentUser.email?.substring(0, 1).toUpperCase() ?? 'U')),
            title: const Text('You (Owner)'),
            subtitle: Text(currentUser.email ?? ''),
          ),
      ],
    );
  }

  // Widget untuk tampilan PEMBACA (bukan pemilik)
  Widget _buildPublicView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        children: [
          const Icon(Icons.link, size: 40, color: Colors.blueAccent),
          const SizedBox(height: 16),
          const Text(
            'Share this link',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.shareUrl,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      )
    );
  }
}