import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'HomeContent.dart';
import 'ProfileContent.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeContent(),
    Center(child: Text('Search', style: TextStyle(color: Colors.white))),
    Center(child: Text('Watchlist', style: TextStyle(color: Colors.white))),
    ProfileContent(),
  ];

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
      body: IndexedStack(
        index: selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF231C30).withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF7C4DFF),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: GoogleFonts.sora(fontSize: 11),
          unselectedLabelStyle: GoogleFonts.sora(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Watchlist'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}