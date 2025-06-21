import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeopleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color primaryBlue;
  final Color textColor;
  final Color subtleTextColor;

  const PeopleCard({
    super.key,
    required this.data,
    required this.primaryBlue,
    required this.textColor,
    required this.subtleTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final email = data['email'] ?? 'No email';
    final String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Container(
       padding: const EdgeInsets.symmetric(vertical: 16.0),
       decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
       child: Row(
         children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryBlue,
              child: Text(
                firstLetter,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(email, style: GoogleFonts.lato(fontSize: 16, color: textColor, fontWeight: FontWeight.bold))),
            OutlinedButton(
              onPressed: () { /* TODO: Implement follow logic */ },
              child: const Text('Ikuti'),
              style: OutlinedButton.styleFrom(
                foregroundColor: subtleTextColor,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
            )
         ],
       ),
    );
  }
}