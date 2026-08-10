import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171023),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171023).withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.movie_filter, color: Color(0xFF7C4DFF)),
            const SizedBox(width: 8),
            Text(
              'CINETRACK',
              style: GoogleFonts.sora(
                color: const Color(0xFF7C4DFF),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBcw_2ZcWdUXREuzusR9UBLTTbyXJvqKaSEwNAbarTC_GVdw--VFuOvTo0Vpu2R5MKMUc9eg5GKn-Mx12stQ2JWXgBadG-q7Y8YWzbtaEfx6u-0P9_JtPNKXxOn61JsilLhnkfQKHx9IE4msmC6PCayx0HtsBWPjdzj-2RpT58VgZyatGkPeYg4WjUzJS-ydYB85tgY8-ciI7pXWkxti05-IEbTXaYUZIPQQ7L237l7XSUw3lgYBzJN',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C4DFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}