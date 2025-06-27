import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onDelete;
  final String title;       
  final String content;    
  final String confirmText; 

  const DeleteConfirmationDialog({
    super.key,
    required this.onDelete,
    this.title = 'Delete Item', // Default value    
    this.content = 'Are you sure you want to delete this item? This action cannot be cancel.', // Default value
    this.confirmText = 'Delete',      
  });

  @override
  Widget build(BuildContext context) {
    const Color destructiveRed = Color(0xFFEF4444);
    const Color textColor = Color(0xFF1F2937);
    const Color subtleTextColor = Color(0xFF6B7280);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: destructiveRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: destructiveRed, size: 32),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title, // Menggunakan parameter title
            style: GoogleFonts.lato(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            content, // Menggunakan parameter content
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 15, color: subtleTextColor),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.lato(color: subtleTextColor, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: destructiveRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(confirmText, style: GoogleFonts.lato(fontWeight: FontWeight.bold)), // Menggunakan parameter confirmText
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}