import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/watchlist_dao.dart';
import '../data/list_dao.dart';
import '../models/movie.dart';
import '../models/movie_list.dart';
import '../services/current_user.dart';
import 'MovieDetailScreen.dart';
import 'ListDetailScreen.dart';

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

  static const List<String> _emojiOptions = [
    '🎬', '🍿', '😂', '😱', '👻', '💕', '🔫', '🚀', '🏆', '🌙', '🎭', '⭐',
  ];

  static const List<Color> _colorOptions = [
    Color(0xFF7C4DFF),
    Color(0xFF00DCE5),
    Color(0xFFFFDB3C),
    Color(0xFFFF6B9D),
    Color(0xFF4CAF50),
    Color(0xFFFF7043),
  ];

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedEmoji = _emojiOptions.first;
    Color selectedColor = _colorOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF231C30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Yeni Liste Oluştur',
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji önizleme + isim alanı
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: selectedColor),
                          ),
                          child: Text(selectedEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
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
                                borderSide: BorderSide(color: selectedColor),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Emoji', style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _emojiOptions.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? selectedColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? selectedColor : Colors.white12,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text('Renk', style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _colorOptions.map((color) {
                        final isSelected = color.toARGB32() == selectedColor.toARGB32();
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Text('Açıklama (opsiyonel)', style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      style: GoogleFonts.manrope(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Bu liste ne hakkında?',
                        hintStyle: GoogleFonts.manrope(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: selectedColor),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final userId = CurrentUser.instance.user?.id;
                    if (name.isEmpty || userId == null) return;

                    final description = descriptionController.text.trim();

                    await _listDao.createList(
                      userId,
                      name,
                      emoji: selectedEmoji,
                      color: '#${selectedColor.toARGB32().toRadixString(16).substring(2)}',
                      description: description.isEmpty ? null : description,
                    );

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
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie)),
                          );
                          // Detay ekranından dönünce watchlist'ten çıkarılmış olabilir,
                          // listeyi güncel tutmak için yeniden çiziyoruz
                          if (mounted) setState(() {});
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: movie.posterUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: const Color(0xFF241A33)),
                                  errorWidget: (context, url, error) => Container(
                                    color: const Color(0xFF241A33),
                                    child: const Icon(Icons.movie, color: Colors.white24),
                                  ),
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
                        ),
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
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.4)),
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
                  ...lists.map((list) {
                    final listColor = _parseColor(list.color) ?? const Color(0xFF7C4DFF);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ListDetailScreen(list: list)),
                        );
                        // Liste silinmiş ya da içeriği değişmiş olabilir, yenile
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: listColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: listColor.withValues(alpha: 0.5)),
                              ),
                              child: (list.emoji?.isNotEmpty ?? false)
                                  ? Text(list.emoji!, style: const TextStyle(fontSize: 18))
                                  : Icon(Icons.list_alt, color: listColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    list.name,
                                    style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  if (list.description?.isNotEmpty ?? false) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      list.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: _listDao.getMovieCountForList(list.id!),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data ?? 0;
                                      return Text(
                                        '$count film',
                                        style: GoogleFonts.jetBrainsMono(color: listColor, fontSize: 11),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white38),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : null;
  }

  Widget _buildFilterChip(String label, {required bool selected}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF7C4DFF).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
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