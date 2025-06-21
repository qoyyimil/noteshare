import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/services/firestore_service.dart';

class ReportDialog extends StatefulWidget {
  final String noteId;
  final String noteOwnerId;
  final String reporterId;

  const ReportDialog({
    super.key,
    required this.noteId,
    required this.noteOwnerId,
    required this.reporterId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  bool _isLoading = false;
  // --- State baru ditambahkan ---
  bool _agreedToTerms = false;
  final TextEditingController _detailsController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _reasons = [
    'Konten Plagiarisme',
    'Tidak Sesuai Kategori',
    'Mengandung Ujaran Kebencian atau SARA',
    'Konten Negatif/Tidak Pantas Lainnya',
  ];

  void _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Silakan pilih alasan laporan.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    // --- Pengecekan syarat dan ketentuan ---
    if (!_agreedToTerms) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Anda harus menyetujui syarat dan ketentuan.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestoreService.addReport(
        noteId: widget.noteId,
        noteOwnerId: widget.noteOwnerId,
        reporterId: widget.reporterId,
        reason: _selectedReason!,
        // --- Mengirim detail dari controller ---
        details: _detailsController.text,
      );
      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Laporan Anda telah berhasil dikirim.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color destructiveRed = Color(0xFFEF4444);
    const Color textColor = Color(0xFF1F2937);
    const Color subtleTextColor = Color(0xFF6B7280);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      // --- Dibungkus dengan SingleChildScrollView agar bisa di-scroll ---
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- Background diubah sesuai permintaan ---
                color: Colors.white, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200)
              ),
              child:
                  // --- Ikon diubah ---
                  const Icon(Icons.info_outline, color: destructiveRed, size: 32),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Laporkan Catatan',
              style: GoogleFonts.lato(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Pilih alasan mengapa Anda melaporkan konten ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 15, color: subtleTextColor),
            ),
            const SizedBox(height: 16),
            // Daftar Pilihan
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason, style: GoogleFonts.lato(color: textColor)),
                value: reason,
                groupValue: _selectedReason,
                activeColor: destructiveRed,
                onChanged: (value) => setState(() => _selectedReason = value),
              );
            }).toList(),
            const SizedBox(height: 16),
            // --- Kolom deskripsi ditambahkan ---
            TextFormField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Berikan detail lebih lanjut...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300)
                )
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // --- Checkbox syarat & ketentuan ---
            CheckboxListTile(
              title: const Text(
                'Saya menyatakan laporan ini dibuat dengan sebenar-benarnya.',
                style: TextStyle(fontSize: 12),
              ),
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() {
                  _agreedToTerms = value!;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: destructiveRed,
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Batal',
                        style: GoogleFonts.lato(
                            color: subtleTextColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: destructiveRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Laporkan',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
