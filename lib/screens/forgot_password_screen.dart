import 'package:flutter/material.dart';
import 'package:noteshare/auth/auth_service.dart';
import 'package:noteshare/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:noteshare/widgets/success_dialog.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Fungsi untuk mengirim link reset password
  void _sendResetLink() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Email cannot be empty."),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return SuccessDialog(
              title: "Check your email",
              description: "We have sent a password reset link to your email. Please check your inbox and follow the instructions to reset your password.",
              buttonText: "Got it",
              onOkPressed: () {
                Navigator.of(dialogContext).pop();
              },
            );
          },
        ).then((_) {
          Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to send link: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Widget Form di sisi kanan
    Widget formSection = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tombol Kembali
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      "Back to login",
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Judul
              const Text("Forgot your password?",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                "Don't worry, happens to all of us. Enter your email below to recover your password.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // Form Email
              const Text("Email",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "john.doe@gmail.com",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        )
                      : const Text("Submit", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: isDesktop
          ? Row(children: [
              // Menggunakan kembali AuthIllustration dari login_screen
              const Expanded(flex: 3, child: AuthIllustration()),
              Expanded(flex: 2, child: formSection),
            ])
          : formSection,
    );
  }
}
