import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // <-- HAPUS BARIS INI JIKA ADA
import 'package:noteshare/auth/auth_gate.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart'; // Tetap import ini untuk menggunakan AuthIllustration

class RegisterScreen extends StatefulWidget {
  final void Function()? onTap;
  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? _selectedEducationLevel;
  bool _agreeToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<String> _educationLevels = ['SMA/SMK', 'Mahasiswa', 'Umum'];

  void signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must agree to the Terms and Privacy Policies.")));
      return;
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signUpWithEmailAndPassword(emailController.text, passwordController.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthGate()), (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign up failed: ${e.toString()}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget registerForm = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sign up NoteShare", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Ayo siapkan akunmu untuk mulai berbagi catatan.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: firstNameController, label: "First Name")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextFormField(controller: lastNameController, label: "Last Name")),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: emailController, label: "Email", hint: "john.doe@gmail.com")),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextFormField(controller: phoneController, label: "Phone Number", inputType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Jenjang Pendidikan", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEducationLevel,
                hint: const Text("Pilih jenjang"),
                items: _educationLevels.map((String level) => DropdownMenuItem<String>(value: level, child: Text(level))).toList(),
                onChanged: (newValue) => setState(() => _selectedEducationLevel = newValue),
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: passwordController,
                  label: "Password",
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(value: _agreeToTerms, onChanged: (value) => setState(() => _agreeToTerms = value!)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        children: const [
                          TextSpan(text: "I agree to all the "),
                          TextSpan(text: "Terms", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          TextSpan(text: " and "),
                          TextSpan(text: "Privacy Policies", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text("Create account", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: widget.onTap, child: const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: isDesktop
          ? Row(children: [Expanded(flex: 2, child: registerForm), const Expanded(flex: 3, child: AuthIllustration())])
          : registerForm,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: inputType,
          decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}