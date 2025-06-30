// lib/screens/edit_profile.dart (Versi Perbaikan Dropdown)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/providers/search_provider.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';
import 'package:noteshare/widgets/search_results_view.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController searchController = TextEditingController();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController educationController = TextEditingController();

  String? _selectedEducationLevel;
  final List<String> _educationLevels = ['High School', 'College Student', 'General'];

  bool _loading = true;
  bool _saving = false;

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color inputFillColor = Color(0xFFF9FAFB);
  static const Color textColor = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    fullNameController.addListener(() => setState(() {}));
    _fetchUserData();
  }
  
  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    aboutController.dispose();
    searchController.dispose();
    educationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final data = doc.data() ?? {};
    
    fullNameController.text = data['fullName'] ?? '';
    emailController.text = data['email'] ?? '';
    phoneController.text = data['phoneNumber'] ?? '';
    birthDateController.text = data['birthDate'] ?? '';
    aboutController.text = data['about'] ?? '';

    final educationLevelFromDB = data['educationLevel'];
    if (educationLevelFromDB != null && _educationLevels.contains(educationLevelFromDB)) {
      _selectedEducationLevel = educationLevelFromDB;
      educationController.text = educationLevelFromDB;
    }
    setState(() => _loading = false);
  }

  Future<void> _pickBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDateController.text.isNotEmpty
          ? DateFormat('d MMMM yyyy').parse(birthDateController.text)
          : DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      birthDateController.text = DateFormat('d MMMM yyyy').format(picked);
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'educationLevel': _selectedEducationLevel,
        'birthDate': birthDateController.text.trim(),
        'about': aboutController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        searchController: searchController,
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: Colors.white,
        searchKeyword: '',
        onClearSearch: () {},
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.searchQuery.isNotEmpty) return const SearchResultsView();
          return child!;
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildProfilePreviewCard(),
                                const SizedBox(height: 24),
                                _buildAboutMeCard(),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 500,
                            child: VerticalDivider(width: 64, thickness: 1, color: borderColor),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _profileField("Full Name", fullNameController),
                                const SizedBox(height: 24),
                                _profileField("Email", emailController, enabled: false),
                                const SizedBox(height: 24),
                                _profileField("Phone Number", phoneController),
                                const SizedBox(height: 24),
                                _profileField("Birth Date", birthDateController, onTap: _pickBirthDate, readOnly: true),
                                const SizedBox(height: 24),
                                _buildEducationDropdown(),
                                const SizedBox(height: 40),
                                _buildActionButtons(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfilePreviewCard() {
    final String name = fullNameController.text;
    final String displayLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: primaryBlue,
            child: Text(
              displayLetter,
              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Display Name",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subtleTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? "Your Name" : name,
                  style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About Me", style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          TextFormField(
            controller: aboutController,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: const InputDecoration.collapsed(
              hintText: "Tell us about yourself...",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true, 
          value: _selectedEducationLevel,
          decoration: _inputDecoration('Education Level'), 
          hint: const Text('Select education level'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedEducationLevel = newValue;
            });
          },
          items: _educationLevels.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _profileField(String label, TextEditingController controller, {bool enabled = true, String? hint, VoidCallback? onTap, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(fontSize: 16, color: enabled ? textColor : subtleTextColor),
      decoration: _inputDecoration(label, hint: hint),
    );
  }
  
  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: inputFillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: borderColor),
            ),
            child: const Text("Cancel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _EditProfilePageState.subtleTextColor)),
          ),
        ),
      ],
    );
  }
}