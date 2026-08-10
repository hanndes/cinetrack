import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';

class MovieDetailScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171023),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  movie.posterUrl,
                  width: double.infinity,
                  height: 420,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: 420,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF171023)],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        movie.imdbRating.toString(),
                        style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${movie.releaseYear} • ${movie.durationMinutes ~/ 60}h ${movie.durationMinutes % 60}m',
                        style: GoogleFonts.manrope(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.genres.join(', '),
                    style: GoogleFonts.manrope(color: const Color(0xFF7C4DFF), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Yönetmen',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.director,
                    style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Konu',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.plot ?? 'Bilgi bulunamadı.',
                    style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Oyuncular',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.cast.isEmpty ? 'Bilgi bulunamadı.' : movie.cast.join(', '),
                    style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}