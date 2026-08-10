import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/watchlist_dao.dart';
import '../data/list_dao.dart';
import '../models/movie.dart';
import '../models/movie_list.dart';
import '../services/current_user.dart';

class WatchlistContent extends StatefulWidget {
  const WatchlistContent({super.key});

  @override
  State<WatchlistContent> createState() => _WatchlistContentState();
}

class _WatchlistContentState extends State<WatchlistContent> with SingleTickerProviderStateMixin {
  final WatchlistDao _watchlistDao = WatchlistDao();
  final ListDao _listDao = ListDao();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF231C30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Yeni Liste Oluştur',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Liste adı',
              hintStyle: GoogleFonts.manrope(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
              onPressed: () async {
                final name = nameController.text.trim();
                final userId = CurrentUser.instance.user?.id;
                if (name.isEmpty || userId == null) return;

                await _listDao.createList(userId, name);

                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
              },
              child: Text('Oluştur', style: GoogleFonts.manrope(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = CurrentUser.instance.user?.id;

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C4DFF),
          labelColor: const Color(0xFF7C4DFF),
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Listelerim'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWatchlistTab(userId),
              _buildListsTab(userId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistTab(int? userId) {
    return FutureBuilder<List<Movie>>(
      future: userId != null ? _watchlistDao.getWatchlistMovies(userId) : Future.value([]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          );
        }

        final movies = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                if (movies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        'Watchlist\'iniz boş',
                        style: GoogleFonts.manrope(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: movies.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.6,
                    ),
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                movie.posterUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.releaseYear} • Movie',
                            style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListsTab(int? userId) {
    return FutureBuilder<List<MovieList>>(
      future: userId != null ? _listDao.getListsForUser(userId) : Future.value([]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          );
        }

        final lists = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showCreateListDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF7C4DFF), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Yeni Liste Oluştur',
                          style: GoogleFonts.jetBrainsMono(color: const Color(0xFF7C4DFF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (lists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Henüz hiç listeniz yok',
                        style: GoogleFonts.manrope(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...lists.map((list) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt, color: Color(0xFF7C4DFF)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            list.name,
                            style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white38),
                      ],
                    ),
                  )),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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