import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../models/movie_list.dart';
import '../data/review_dao.dart';
import '../data/list_dao.dart';
import '../data/watchlist_dao.dart';
import '../services/current_user.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final ReviewDao _reviewDao = ReviewDao();
  final ListDao _listDao = ListDao();
  final WatchlistDao _watchlistDao = WatchlistDao();
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 5;
  bool _isSubmitting = false;
  bool _isInWatchlist = false;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
    _loadWatchlistStatus();
  }

  Future<void> _loadWatchlistStatus() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;
    final result = await _watchlistDao.isInWatchlist(user!.id!, widget.movie.id!);
    if (mounted) setState(() => _isInWatchlist = result);
  }

  Future<void> _toggleWatchlist() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final userId = user!.id!;
    final movieId = widget.movie.id!;

    if (_isInWatchlist) {
      await _watchlistDao.removeFromWatchlist(userId, movieId);
    } else {
      await _watchlistDao.addToWatchlist(userId, movieId);
    }

    setState(() => _isInWatchlist = !_isInWatchlist);
  }

  Future<List<Review>> _loadReviews() {
    return _reviewDao.getReviewsForMovie(widget.movie.id!);
  }

  Future<void> _submitReview() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir yorum yazın'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await _reviewDao.addReview(
      user!.id!,
      widget.movie.id!,
      _selectedRating,
      _reviewController.text.trim(),
    );

    _reviewController.clear();

    setState(() {
      _selectedRating = 5;
      _isSubmitting = false;
      _reviewsFuture = _loadReviews();
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // ---- LİSTEYE EKLEME ----

  Future<void> _openAddToListSheet() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final userId = user!.id!;
    final movieId = widget.movie.id!;

    var lists = await _listDao.getListsForUser(userId);
    var selectedListIds = await _listDao.getListIdsContainingMovie(userId, movieId);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1730),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> toggleList(MovieList list) async {
              final isSelected = selectedListIds.contains(list.id);
              if (isSelected) {
                await _listDao.removeMovieFromList(list.id!, movieId);
                setSheetState(() => selectedListIds.remove(list.id));
              } else {
                await _listDao.addMovieToList(list.id!, movieId);
                setSheetState(() => selectedListIds.add(list.id!));
              }
            }

            Future<void> createNewList() async {
              final nameController = TextEditingController();
              final newName = await showDialog<String>(
                context: sheetContext,
                builder: (dialogContext) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E1730),
                    title: Text(
                      'Yeni Liste',
                      style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    content: TextField(
                      controller: nameController,
                      autofocus: true,
                      style: GoogleFonts.manrope(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Liste adı',
                        hintStyle: GoogleFonts.manrope(color: Colors.white38),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF7C4DFF)),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, nameController.text.trim()),
                        child: Text(
                          'Oluştur',
                          style: GoogleFonts.manrope(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (newName == null || newName.isEmpty) return;

              final newListId = await _listDao.createList(userId, newName);
              await _listDao.addMovieToList(newListId, movieId);

              final updatedLists = await _listDao.getListsForUser(userId);
              setSheetState(() {
                lists = updatedLists;
                selectedListIds.add(newListId);
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listeye Ekle',
                      style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    if (lists.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Henüz bir listen yok.',
                          style: GoogleFonts.manrope(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: lists.length,
                          itemBuilder: (context, index) {
                            final list = lists[index];
                            final isSelected = selectedListIds.contains(list.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) => toggleList(list),
                              activeColor: const Color(0xFF7C4DFF),
                              checkColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                list.name,
                                style: GoogleFonts.manrope(color: Colors.white, fontSize: 14),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: createNewList,
                      icon: const Icon(Icons.add, color: Color(0xFF7C4DFF)),
                      label: Text(
                        'Yeni Liste Oluştur',
                        style: GoogleFonts.manrope(color: const Color(0xFF7C4DFF), fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          style: GoogleFonts.sora(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleWatchlist,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                            color: const Color(0xFF7C4DFF),
                            size: 22,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _openAddToListSheet,
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.playlist_add, color: Color(0xFF7C4DFF), size: 22),
                        ),
                      ),
                    ],
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

                  // ---- YORUMLAR BÖLÜMÜ ----
                  Text(
                    'Yorumlar',
                    style: GoogleFonts.sora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewForm(),
                  const SizedBox(height: 24),
                  _buildReviewsList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Puanınız',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(10, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = starValue.toDouble()),
                child: Icon(
                  starValue <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 22,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: GoogleFonts.manrope(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Bu film hakkında ne düşünüyorsun?',
              hintStyle: GoogleFonts.manrope(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                'Yorumu Gönder',
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return FutureBuilder<List<Review>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Henüz yorum yok. İlk yorumu sen yaz!',
              style: GoogleFonts.manrope(color: Colors.white38, fontSize: 13),
            ),
          );
        }

        return Column(
          children: reviews.map((review) => _buildReviewTile(review)).toList(),
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];

    return '${date.day} ${aylar[date.month - 1]} ${date.year}';
  }

  Widget _buildReviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.3),
                child: Text(
                  (review.userName?.isNotEmpty ?? false) ? review.userName![0].toUpperCase() : '?',
                  style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Kullanıcı',
                      style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (review.reviewDate != null)
                      Text(
                        _formatDate(review.reviewDate!),
                        style: GoogleFonts.manrope(color: Colors.white38, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(0),
                    style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.reviewText!,
              style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}