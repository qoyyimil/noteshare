import 'package:flutter/material.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // For AuthIllustration & LoginScreen

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

  String? _emailError;
  String? _passwordError;
  String? _phoneError;

  final List<String> _educationLevels = [
    'High School',
    'College Student',
    'General'
  ];

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmail);
    phoneController.addListener(_validatePhone);
    passwordController.addListener(_validatePassword);
  }

  void _validateEmail() {
    final email = emailController.text;
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _emailError = emailRegex.hasMatch(email)
          ? null
          : "Please enter a valid email address";
    });
  }

  void _validatePhone() {
    final phone = phoneController.text;
    if (phone.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }
    setState(() {
      _phoneError = RegExp(r'^\d+$').hasMatch(phone)
          ? null
          : "Phone Number must contain digits only!";
    });
  }

  void _validatePassword() {
    final password = passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }
    final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    setState(() {
      _passwordError = (password.length >= 6 && hasLetter && hasNumber)
          ? null
          : "Password must contain letters, numbers, and be at least 6 characters";
    });
  }

  @override
  void dispose() {
    emailController.removeListener(_validateEmail);
    phoneController.removeListener(_validatePhone);
    passwordController.removeListener(_validatePassword);
    super.dispose();
  }

  void _showEmailVerificationPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 350,
                maxHeight: 500,
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 48,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Verify your email',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A verification link has been sent to your email address.\n\nPlease check your inbox and click the link to activate your account.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginScreen(onTap: null),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "OK",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void signUp() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        _selectedEducationLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields must be filled!")),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text)) {
      setState(() {
        _emailError = "Please enter a valid email address";
      });
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(phoneController.text)) {
      setState(() {
        _phoneError = "Phone Number must contain digits only!";
      });
      return;
    }

    final password = passwordController.text;
    final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    if (password.length < 6 || !hasLetter || !hasNumber) {
      setState(() {
        _passwordError =
            "Password must contain letters, numbers, and be at least 6 characters";
      });
      return;
    }

    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("You must agree to the Terms and Privacy Policies.")),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signUpWithEmailAndPassword(
          emailController.text, password);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showEmailVerificationPopup(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign up failed: ${e.toString()}")),
        );
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
              const Text("Sign up NoteShare",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Get your account ready to start sharing notes.",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                      child: _buildTextFormField(
                          controller: firstNameController,
                          label: "First Name",
                          requiredField: true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextFormField(
                          controller: lastNameController,
                          label: "Last Name",
                          requiredField: true)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: emailController,
                label: "Email",
                hint: "john.doe@gmail.com",
                requiredField: true,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: phoneController,
                label: "Phone Number",
                inputType: TextInputType.phone,
                requiredField: true,
                errorText: _phoneError,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text("Education Level",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Text(" *", style: TextStyle(color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedEducationLevel,
                hint: const Text("Select education level"),
                items: _educationLevels
                    .map((String level) => DropdownMenuItem<String>(
                        value: level, child: Text(level)))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => _selectedEducationLevel = newValue),
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: passwordController,
                label: "Password",
                obscureText: !_isPasswordVisible,
                requiredField: true,
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: confirmPasswordController,
                label: "Confirm Password",
                obscureText: !_isConfirmPasswordVisible,
                requiredField: true,
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() =>
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) =>
                          setState(() => _agreeToTerms = value!)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                        children: const [
                          TextSpan(text: "I agree to all the "),
                          TextSpan(
                              text: "Terms",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(text: " and "),
                          TextSpan(
                              text: "Privacy Policies",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold)),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text("Create account",
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 4),
                  GestureDetector(
                      onTap: widget.onTap,
                      child: const Text("Sign in",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: isDesktop
          ? Row(children: [
              Expanded(flex: 2, child: registerForm),
              const Expanded(flex: 3, child: AuthIllustration())
            ])
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
    bool requiredField = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (requiredField)
              const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: hint != null
                ? const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: suffixIcon,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
