// lib/widgets/success_dialog.dart (Updated)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onOkPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.description,
    this.buttonText = "OK",
    required this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Warna biru primer dari aplikasi Anda
    const Color primaryBlue = Color(0xFF3B82F6);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5,
      backgroundColor: Colors.white,
      child: Container(
        // 1. Batasi Lebar Dialog
        width: 350, // Atur lebar maksimum dialog agar tidak terlalu lebar di desktop
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Ikon Email
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // 2. Ganti Warna
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                // 2. Ganti Warna
                color: primaryBlue,
                size: 50,
              ),
            ),
            const SizedBox(height: 24.0),

            // Judul
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),

            // Deskripsi
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24.0),

            // Tombol OK
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOkPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}