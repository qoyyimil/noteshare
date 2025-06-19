import 'package:flutter/material.dart';
import 'package:noteshare/auth/login_or_register.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Function to navigate to the authentication page
  void _navigateToAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginOrRegister()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // A common breakpoint for mobile is 768, but you can adjust it
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NoteShare',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Show row of buttons for desktop view
                    if (!isMobile)
                      Row(
                        children: [
                          TextButton(onPressed: () => _navigateToAuth(context), child: const Text('Write', style: TextStyle(color: Colors.black87, fontSize: 16))),
                          const SizedBox(width: 20),
                          TextButton(onPressed: () => _navigateToAuth(context), child: const Text('Sign in', style: TextStyle(color: Colors.black87, fontSize: 16))),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () => _navigateToAuth(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ],
                      ),
                    // Show a simple menu icon for mobile view
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87),
                        onPressed: () => _navigateToAuth(context),
                      ),
                  ],
                ),
              ),
              // 2. Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: isMobile
                    // Mobile Layout: Image on top, text below
                    ? Column(
                        children: [
                          _buildLandingImage(),
                          const SizedBox(height: 40),
                          ..._buildLandingContent(isMobile, context), // "..." is a spread operator to insert list elements
                        ],
                      )
                    // Desktop Layout: Text on the left, image on the right
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2, // Text takes less space
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildLandingContent(isMobile, context),
                            ),
                          ),
                          const SizedBox(width: 60),
                          Expanded(
                            flex: 3, // Image takes more space
                            child: _buildLandingImage(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build the text content to avoid code repetition
  List<Widget> _buildLandingContent(bool isMobile, BuildContext context) {
    return [
      Text(
        'Write to share.\nShare to inspire.',
        style: TextStyle(
          fontSize: isMobile ? 40 : 56,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          height: 1.2,
        ),
        textAlign: isMobile ? TextAlign.center : TextAlign.start,
      ),
      const SizedBox(height: 24),
      Text(
        'Where you read to learn, write to express, and connect through stories.',
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          color: Colors.black54,
          height: 1.5,
        ),
        textAlign: isMobile ? TextAlign.center : TextAlign.start,
      ),
      const SizedBox(height: 40),
      ElevatedButton(
        onPressed: () => _navigateToAuth(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2), // A nice blue color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: const Text('Start Reading'),
      ),
    ];
  }

  // Helper function for the image
  Widget _buildLandingImage() {
    // This path MUST match the filename in your assets folder
    return Image.asset(
      'assets/landing_page.png',
      fit: BoxFit.contain,
    );
  }
}