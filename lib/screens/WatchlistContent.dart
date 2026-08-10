import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WatchlistContent extends StatelessWidget {
  const WatchlistContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'My Watchlist',
              style: GoogleFonts.sora(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('All', selected: true),
                  _buildFilterChip('Movies', selected: false),
                  _buildFilterChip('TV Shows', selected: false),
                  _buildFilterChip('Seen', selected: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool selected}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF7C4DFF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF7C4DFF) : Colors.white24,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: selected ? const Color(0xFF7C4DFF) : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}