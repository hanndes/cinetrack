import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../models/review.dart';
import '../models/movie_list.dart';
import '../data/movie_dao.dart';
import '../data/review_dao.dart';
import '../data/list_dao.dart';
import '../data/watchlist_dao.dart';
import '../data/watched_dao.dart';
import '../services/current_user.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final ReviewDao _reviewDao = ReviewDao();
  final ListDao _listDao = ListDao();
  final WatchlistDao _watchlistDao = WatchlistDao();
  final WatchedDao _watchedDao = WatchedDao();
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 5;
  bool _isSubmitting = false;
  bool _isInWatchlist = false;
  bool _isWatched = false;
  int? _editingReviewId;
  late Future<List<Review>> _reviewsFuture;
  late Future<Movie?> _movieFuture;
  final MovieDao _movieDao = MovieDao();

  @override
  void initState() {
    super.initState();
    _movieFuture = _movieDao.getMovieById(widget.movieId);
    _reviewsFuture = _loadReviews();
    _loadWatchlistStatus();
    _loadWatchedStatus();
  }

  Future<void> _loadWatchlistStatus() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;
    final result = await _watchlistDao.isInWatchlist(user!.id!, widget.movieId);
    if (mounted) setState(() => _isInWatchlist = result);
  }

  Future<void> _loadWatchedStatus() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;
    final result = await _watchedDao.isWatched(user!.id!, widget.movieId);
    if (mounted) setState(() => _isWatched = result);
  }

  Future<void> _toggleWatched() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final userId = user!.id!;
    final movieId = widget.movieId;

    if (_isWatched) {
      await _watchedDao.unmarkAsWatched(userId, movieId);
    } else {
      await _watchedDao.markAsWatched(userId, movieId);
    }

    setState(() => _isWatched = !_isWatched);
  }

  Future<void> _toggleWatchlist() async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final userId = user!.id!;
    final movieId = widget.movieId;

    if (_isInWatchlist) {
      await _watchlistDao.removeFromWatchlist(userId, movieId);
    } else {
      await _watchlistDao.addToWatchlist(userId, movieId);
    }

    setState(() => _isInWatchlist = !_isInWatchlist);
  }

  Future<List<Review>> _loadReviews() {
    return _reviewDao.getReviewsForMovie(widget.movieId);
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

    if (_editingReviewId != null) {
      await _reviewDao.updateReview(
        _editingReviewId!,
        user!.id!,
        _selectedRating,
        _reviewController.text.trim(),
      );
    } else {
      await _reviewDao.addReview(
        user!.id!,
        widget.movieId,
        _selectedRating,
        _reviewController.text.trim(),
      );
    }

    _reviewController.clear();

    setState(() {
      _selectedRating = 5;
      _isSubmitting = false;
      _editingReviewId = null;
      _reviewsFuture = _loadReviews();
    });
  }

  void _startEditingReview(Review review) {
    setState(() {
      _editingReviewId = review.id;
      _selectedRating = review.rating;
      _reviewController.text = review.reviewText ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingReviewId = null;
      _selectedRating = 5;
      _reviewController.clear();
    });
  }

  Future<void> _confirmDeleteReview(Review review) async {
    final user = CurrentUser.instance.user;
    if (user?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1730),
          title: Text(
            'Yorumu Sil',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Bu yorumu silmek istediğine emin misin?',
            style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Sil',
                style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _reviewDao.deleteReview(review.id!, user!.id!);

    // Eğer silinen yorum düzenleme modundaysa formu da temizle
    if (_editingReviewId == review.id) {
      _cancelEditing();
    }

    setState(() {
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
    final movieId = widget.movieId;

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
    return FutureBuilder<Movie?>(
      future: _movieFuture,
      builder: (context, movieSnapshot) {
        if (movieSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF171023),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
          );
        }

        final movie = movieSnapshot.data;
        if (movie == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF171023),
            appBar: AppBar(backgroundColor: const Color(0xFF171023), elevation: 0),
            body: Center(
              child: Text('Film bulunamadı', style: GoogleFonts.manrope(color: Colors.white70)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF171023),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: movie.posterUrl,
                      width: double.infinity,
                      height: 420,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 420,
                        color: const Color(0xFF241A33),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 420,
                        color: const Color(0xFF241A33),
                        child: const Icon(Icons.movie, color: Colors.white24, size: 48),
                      ),
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
                            onTap: _toggleWatched,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isWatched
                                    ? Colors.greenAccent.withValues(alpha: 0.15)
                                    : const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isWatched ? Icons.check_circle : Icons.check_circle_outline,
                                color: _isWatched ? Colors.greenAccent : const Color(0xFF7C4DFF),
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleWatchlist,
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
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
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
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
      },
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editingReviewId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF7C4DFF), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Yorumu düzenliyorsun',
                    style: GoogleFonts.manrope(color: const Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelEditing,
                    child: Text(
                      'İptal',
                      style: GoogleFonts.manrope(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
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
              fillColor: Colors.white.withValues(alpha: 0.05),
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
                _editingReviewId != null ? 'Yorumu Güncelle' : 'Yorumu Gönder',
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
    final currentUserId = CurrentUser.instance.user?.id;
    final isOwnReview = review.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
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
              if (isOwnReview) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _startEditingReview(review),
                  child: const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _confirmDeleteReview(review),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                ),
              ],
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