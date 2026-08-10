import '../models/movie.dart';
import 'database_helper.dart';

class MovieDao {
  final dbHelper = DatabaseHelper.instance;

  // Bir filmin türlerini getir
  Future<List<String>> _getGenresForMovie(int movieId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT genres.name FROM genres
      INNER JOIN movie_genres ON genres.id = movie_genres.genreId
      WHERE movie_genres.movieId = ?
    ''', [movieId]);
    return maps.map((map) => map['name'] as String).toList();
  }

  // Bir filmin oyuncularını getir
  Future<List<String>> _getCastForMovie(int movieId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT artists.name FROM artists
      INNER JOIN movie_cast ON artists.id = movie_cast.artistId
      WHERE movie_cast.movieId = ?
    ''', [movieId]);
    return maps.map((map) => map['name'] as String).toList();
  }

  // Bir map'i, genres/cast bilgisiyle birlikte Movie'ye çevir
  Future<Movie> _mapToMovieWithDetails(Map<String, dynamic> map) async {
    final movieId = map['id'] as int;
    final genres = await _getGenresForMovie(movieId);
    final cast = await _getCastForMovie(movieId);
    return Movie.fromMap(map, genres: genres, cast: cast);
  }

  // Tek film ekle
  Future<int> insertMovie(Movie movie) async {
    final db = await dbHelper.database;
    return await db.insert('movies', movie.toMap()..remove('id'));
  }

  // Tüm filmleri getir (genres/cast dahil)
  Future<List<Movie>> getAllMovies() async {
    final db = await dbHelper.database;
    final maps = await db.query('movies');
    final movies = <Movie>[];
    for (final map in maps) {
      movies.add(await _mapToMovieWithDetails(map));
    }
    return movies;
  }

  // ID ile tek film getir (genres/cast dahil)
  Future<Movie?> getMovieById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'movies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return await _mapToMovieWithDetails(maps.first);
    }
    return null;
  }

  // Film adına göre ara
  Future<List<Movie>> searchMovies(String query) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'movies',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
    );
    final movies = <Movie>[];
    for (final map in maps) {
      movies.add(await _mapToMovieWithDetails(map));
    }
    return movies;
  }

  // Bir filme tür ekle (genre yoksa oluşturur)
  Future<void> addGenreToMovie(int movieId, String genreName) async {
    final db = await dbHelper.database;

    // Genre zaten var mı kontrol et
    final existing = await db.query('genres', where: 'name = ?', whereArgs: [genreName]);
    int genreId;
    if (existing.isNotEmpty) {
      genreId = existing.first['id'] as int;
    } else {
      genreId = await db.insert('genres', {'name': genreName});
    }

    await db.insert('movie_genres', {'movieId': movieId, 'genreId': genreId});
  }

  // Bir filme oyuncu ekle (artist yoksa oluşturur)
  Future<void> addCastToMovie(int movieId, String artistName) async {
    final db = await dbHelper.database;

    final existing = await db.query('artists', where: 'name = ?', whereArgs: [artistName]);
    int artistId;
    if (existing.isNotEmpty) {
      artistId = existing.first['id'] as int;
    } else {
      artistId = await db.insert('artists', {'name': artistName});
    }

    await db.insert('movie_cast', {'movieId': movieId, 'artistId': artistId});
  }

  // Tablo boş mu kontrol et (seed işlemi için)
  Future<bool> isEmpty() async {
    final db = await dbHelper.database;
    final result = await db.query('movies', limit: 1);
    return result.isEmpty;
  }

  // Veritabanı boşsa dummy filmleri ekle (genres/cast dahil)
  Future<void> seedMoviesIfEmpty(List<Movie> movies) async {
    final empty = await isEmpty();
    if (empty) {
      for (final movie in movies) {
        final movieId = await insertMovie(movie);
        for (final genre in movie.genres) {
          await addGenreToMovie(movieId, genre);
        }
        for (final actor in movie.cast) {
          await addCastToMovie(movieId, actor);
        }
      }
    }
  }
}