import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noteshare/widgets/home/home_app_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController searchController = TextEditingController();

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  bool _loading = false;
  bool _saving = false;

  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color subtleTextColor = Color(0xFF6B7280);
  static const Color sidebarBgColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final data = doc.data() ?? {};
    fullNameController.text = data['fullName'] ?? '';
    emailController.text = data['email'] ?? '';
    phoneController.text = data['phone'] ?? '';
    phoneController.text = data['phoneNumber'] ?? '';
    educationController.text = data['educationLevel'] ?? '';
    birthDateController.text = data['birthDate'] ?? '';
    aboutController.text = data['about'] ?? '';
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
      
      // Update email di Firebase Auth jika berubah
      if (emailController.text.trim() != currentUser!.email) {
        await currentUser!.updateEmail(emailController.text.trim());
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'educationLevel': educationController.text.trim(),
        'birthDate': birthDateController.text.trim(),
        'about': aboutController.text.trim(),
        'email': emailController.text.trim(), // update email di Firestore juga
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        searchController: searchController,
        searchKeyword: '',
        onClearSearch: () {},
        // onMenuItemSelected: (value, context) {},
        currentUser: currentUser,
        primaryBlue: primaryBlue,
        subtleTextColor: subtleTextColor,
        sidebarBgColor: sidebarBgColor,
      ),
      body: _loading
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
                        // LEFT COLUMN: Profile Card & About Me
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      children: [
                                        const CircleAvatar(
                                          radius: 40,
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.person, size: 60, color: Colors.white),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                          child: const Text("Change Photo"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fullNameController.text,
                                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: const [
                                              Text("36", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                              SizedBox(width: 4),
                                              Text("Followers", style: TextStyle(color: Colors.black54)),
                                              SizedBox(width: 24),
                                              Text("100", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                              SizedBox(width: 4),
                                              Text("Following", style: TextStyle(color: Colors.black54)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text("About Me", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  controller: aboutController,
                                  maxLines: 6,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // VERTICAL DIVIDER
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          color: Colors.grey.shade300,
                        ),
                        // RIGHT COLUMN: Editable Fields
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _profileField("Email", emailController, enabled: true),
                              const SizedBox(height: 24),
                              _profileField("Phone Number", phoneController),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: _pickBirthDate,
                                child: AbsorbPointer(
                                  child: _profileField(
                                    "Birth Date",
                                    birthDateController,
                                    hint: "Select birth date",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _profileField("Education Level", educationController),
                              const SizedBox(height: 40),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saving ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: _saving
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white, strokeWidth: 2),
                                            )
                                          : const Text("Save", style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _saving
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade200,
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      ),
                                      child: const Text("Cancel", style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _profileField(String label, TextEditingController controller,
      {bool enabled = true, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}