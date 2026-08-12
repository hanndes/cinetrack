import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/list_dao.dart';
import '../models/movie.dart';
import '../models/movie_list.dart';

class ListDetailScreen extends StatefulWidget {
  final int listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final ListDao _listDao = ListDao();
  late Future<List<Movie>> _moviesFuture;

  // Liste bilgisi artik id uzerinden veritabanindan cekiliyor (go_router /
  // deep linking icin gerekli). _listFuture ilk yuklemeyi bekler,
  // _currentList ise duzenleme sonrasi ekrani guncel gostermek icin
  // yerel kopyayi tutar.
  late Future<MovieList?> _listFuture;
  MovieList? _currentList;

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

  @override
  void initState() {
    super.initState();
    _moviesFuture = _loadMovies();
    _listFuture = _loadList();
  }

  Future<MovieList?> _loadList() async {
    final list = await _listDao.getListById(widget.listId);
    if (mounted) {
      setState(() => _currentList = list);
    }
    return list;
  }

  Future<List<Movie>> _loadMovies() {
    return _listDao.getMoviesInList(widget.listId);
  }

  Future<void> _removeMovie(Movie movie) async {
    await _listDao.removeMovieFromList(widget.listId, movie.id!);
    setState(() {
      _moviesFuture = _loadMovies();
    });
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : null;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  void _showEditListDialog() {
    final nameController = TextEditingController(text: _currentList!.name);
    final descriptionController = TextEditingController(text: _currentList!.description ?? '');
    String selectedEmoji = _currentList!.emoji ?? _emojiOptions.first;
    Color selectedColor = _parseColor(_currentList!.color) ?? _colorOptions.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF231C30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Listeyi Düzenle',
                style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('İptal', style: GoogleFonts.manrope(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: selectedColor),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final description = descriptionController.text.trim();
                    final colorHex = _colorToHex(selectedColor);

                    await _listDao.updateListDetails(
                      widget.listId,
                      name: name,
                      emoji: selectedEmoji,
                      color: colorHex,
                      description: description.isEmpty ? null : description,
                    );

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);

                    setState(() {
                      _currentList = MovieList(
                        id: widget.listId,
                        userId: _currentList!.userId,
                        name: name,
                        emoji: selectedEmoji,
                        color: colorHex,
                        description: description.isEmpty ? null : description,
                        createdDate: _currentList!.createdDate,
                      );
                    });
                  },
                  child: Text('Kaydet', style: GoogleFonts.manrope(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1730),
          title: Text(
            'Listeyi Sil',
            style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '"${_currentList!.name}" listesini silmek istediğine emin misin? Bu işlem geri alınamaz.',
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

    await _listDao.deleteList(widget.listId);

    if (!mounted) return;
    // Silindiğini önceki ekrana bildirmek için true döndürerek geri dönüyoruz
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MovieList?>(
      future: _listFuture,
      builder: (context, listSnapshot) {
        if (listSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF171023),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
          );
        }

        final list = listSnapshot.data;
        if (list == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF171023),
            appBar: AppBar(backgroundColor: const Color(0xFF171023), elevation: 0),
            body: Center(
              child: Text('Liste bulunamadı', style: GoogleFonts.manrope(color: Colors.white70)),
            ),
          );
        }

        final listColor = _parseColor(list.color) ?? const Color(0xFF7C4DFF);

        return Scaffold(
          backgroundColor: const Color(0xFF171023),
          appBar: AppBar(
            backgroundColor: const Color(0xFF171023),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                if (list.emoji?.isNotEmpty ?? false) ...[
                  Text(list.emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    list.name,
                    style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                onPressed: _showEditListDialog,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _confirmDeleteList,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (list.description?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: listColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: listColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      list.description!,
                      style: GoogleFonts.manrope(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
              Expanded(
                child: FutureBuilder<List<Movie>>(
                  future: _moviesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
                      );
                    }

                    final movies = snapshot.data!;

                    if (movies.isEmpty) {
                      return Center(
                        child: Text(
                          'Bu listede henüz film yok',
                          style: GoogleFonts.manrope(color: Colors.white54, fontSize: 14),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
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
                            await context.push('/movie/${movie.id}');
                            if (mounted) setState(() => _moviesFuture = _loadMovies());
                          },
                          onLongPress: () => _removeMovie(movie),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: CachedNetworkImage(
                                        imageUrl: movie.posterUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: const Color(0xFF241A33)),
                                        errorWidget: (context, url, error) => Container(
                                          color: const Color(0xFF241A33),
                                          child: const Icon(Icons.movie, color: Colors.white24),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => _removeMovie(movie),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.55),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                '${movie.releaseYear}',
                                style: GoogleFonts.manrope(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}