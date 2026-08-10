import '../models/movie.dart';
import 'database_helper.dart';

class MovieDao {
  final dbHelper = DatabaseHelper.instance;

  // Tek film ekle
  Future<int> insertMovie(Movie movie) async {
    final db = await dbHelper.database;
    return await db.insert('movies', movie.toMap()..remove('id'));
  }

  // Tüm filmleri getir
  Future<List<Movie>> getAllMovies() async {
    final db = await dbHelper.database;
    final maps = await db.query('movies');
    return maps.map((map) => Movie.fromMap(map)).toList();
  }

  // ID ile tek film getir
  Future<Movie?> getMovieById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'movies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Movie.fromMap(maps.first);
    }
    return null;
  }

  // Tablo boş mu kontrol et (seed işlemi için)
  Future<bool> isEmpty() async {
    final db = await dbHelper.database;
    final result = await db.query('movies', limit: 1);
    return result.isEmpty;
  }

  // Veritabanı boşsa dummy filmleri ekle
  Future<void> seedMoviesIfEmpty(List<Movie> movies) async {
    final empty = await isEmpty();
    if (empty) {
      for (final movie in movies) {
        await insertMovie(movie);
      }
    }
  }
}