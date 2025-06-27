import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noteshare/screens/create_note_screen.dart';
import 'package:noteshare/screens/home_screen.dart';
import 'package:noteshare/screens/profile.dart';
import 'package:noteshare/screens/my_bookmarks_screen.dart';
import 'package:noteshare/screens/my_notes_screen.dart';
import 'package:noteshare/screens/login_screen.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String searchKeyword;
  final VoidCallback onClearSearch;
  final User? currentUser;
  final Color primaryBlue;
  final Color subtleTextColor;
  final Color sidebarBgColor;

  const HomeAppBar({
    super.key,
    required this.searchController,
    required this.searchKeyword,
    required this.onClearSearch,
    required this.currentUser,
    required this.primaryBlue,
    required this.subtleTextColor,
    required this.sidebarBgColor,
  });

  void _onMenuItemSelected(String value, BuildContext context) async {
    if (value == 'profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else if (value == 'library') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyBookmarksScreen()),
      );
    } else if (value == 'notes') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyNotesScreen()),
      );
    } else if (value == 'logout') {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(onTap: null)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to home screen when logo is tapped
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Image.asset(
                    'assets/Logo.png',
                    height: 22,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'NoteShare',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    style: GoogleFonts.lato(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search notes or users...',
                      hintStyle: TextStyle(color: subtleTextColor),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: Colors.grey),
                      suffixIcon: searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 20, color: Colors.grey),
                              onPressed: onClearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: sidebarBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 0),
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateNoteScreen()),
                ),
                icon:
                    Icon(Icons.edit_outlined, color: subtleTextColor, size: 20),
                label: Text('Write',
                    style: GoogleFonts.lato(color: subtleTextColor)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[100],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_none, color: subtleTextColor),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuItemSelected(value, context),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'library',
                    child: ListTile(
                      leading: Icon(Icons.bookmark_border),
                      title: Text('Library'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'notes',
                    child: ListTile(
                      leading: Icon(Icons.note_alt_outlined),
                      title: Text('My Notes'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'stats',
                    child: ListTile(
                      leading: Icon(Icons.bar_chart_outlined),
                      title: Text('Statistics'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Log Out'),
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryBlue,
                  child: Text(
                    (currentUser?.email?.isNotEmpty ?? false)
                        ? currentUser!.email![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
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
