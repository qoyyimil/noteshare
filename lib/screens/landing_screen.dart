import 'package:flutter/material.dart';
import 'package:noteshare/auth/login_or_register.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key,});

  void _navigateToAuth(BuildContext context, {required bool isInitialLogin}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginOrRegister(initialIsLogin: isInitialLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    // final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NoteShare',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  if (isDesktop)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _navigateToAuth(context, isInitialLogin: false),
                          child: const Text('Write', style: TextStyle(color: Colors.black87, fontSize: 16)),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: () => _navigateToAuth(context, isInitialLogin: true),
                          child: const Text('Sign in', style: TextStyle(color: Colors.black87, fontSize: 16)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () => _navigateToAuth(context, isInitialLogin: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ],
                    ),
                  if (!isDesktop)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black87),
                      onPressed: () => _navigateToAuth(context, isInitialLogin: false),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildLandingContent(context),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            flex: 3,
                            child: _buildLandingImage(isDesktop),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLandingImage(isDesktop),
                          const SizedBox(height: 20),
                          ..._buildLandingContent(context),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLandingContent(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return [
      Text(
        'Write to share.\nShare to inspire.',
        style: TextStyle(
          fontSize: isDesktop ? 56 : 40,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.2,
        ),
        textAlign: isDesktop ? TextAlign.start : TextAlign.center,
      ),
      const SizedBox(height: 20),
      Text(
        'Where you read to learn, write to express, and connect through stories.',
        style: TextStyle(
          fontSize: isDesktop ? 18 : 16,
          color: Colors.black54,
          height: 1.5,
        ),
        textAlign: isDesktop ? TextAlign.start : TextAlign.center,
      ),
      const SizedBox(height: 30),
      ElevatedButton(
        onPressed: () => _navigateToAuth(context, isInitialLogin: false),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: const Text('Start Reading'),
      ),
    ];
  }

  // Helper widget untuk gambar
  Widget _buildLandingImage(bool isDesktop) {
    return Image.asset(
      'assets/landing_page.png',
      fit: BoxFit.contain,
    );
  }
}