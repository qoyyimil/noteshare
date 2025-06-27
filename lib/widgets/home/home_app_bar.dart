import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/screens/create_note_screen.dart';


class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String searchKeyword;
  final VoidCallback onClearSearch;
  final Function(String, BuildContext) onMenuItemSelected;
  final User? currentUser;
  final Color primaryBlue;
  final Color subtleTextColor;
  final Color sidebarBgColor;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.searchKeyword,
    required this.onClearSearch,
    required this.onMenuItemSelected,
    required this.currentUser,
    required this.primaryBlue,
    required this.subtleTextColor,
    required this.sidebarBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white, // Pastikan ini putih
      elevation: 0, // Pastikan elevation 0
      shadowColor: Colors.transparent, // Tambahkan ini
      surfaceTintColor: Colors.white, // Tambahkan ini
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Image.asset(
                  'assets/Logo.png',
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Text('NoteShare'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes or users...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      suffixIcon: searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                              onPressed: onClearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: sidebarBgColor,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateNoteScreen())),
                icon: Icon(Icons.edit_outlined, color: subtleTextColor, size: 20),
                label: Text('Write', style: GoogleFonts.lato(color: subtleTextColor)),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[100]),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: subtleTextColor)),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) => onMenuItemSelected(value, context),
                offset: const Offset(0, 40),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryBlue,
                  child: Text(
                    currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(value: 'profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profile'))),
                  const PopupMenuItem<String>(value: 'library', child: ListTile(leading: Icon(Icons.bookmark_border), title: Text('Saved Notes'))),
                  const PopupMenuItem<String>(value: 'notes', child: ListTile(leading: Icon(Icons.note_alt_outlined), title: Text('My Notes'))),
                  const PopupMenuItem<String>(value: 'stats', child: ListTile(leading: Icon(Icons.bar_chart_outlined), title: Text('Statistics'))),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Log Out'))),
                ],
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}