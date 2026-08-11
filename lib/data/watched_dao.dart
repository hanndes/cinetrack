import '../models/movie.dart';
import 'database_helper.dart';

class WatchedDao {
  final dbHelper = DatabaseHelper.instance;

  // Filmi izlendi olarak işaretle
  Future<void> markAsWatched(int userId, int movieId) async {
    final db = await dbHelper.database;
    // Zaten işaretliyse tekrar eklemeyelim
    final existing = await db.query(
      'watched',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
    if (existing.isNotEmpty) return;

    await db.insert('watched', {
      'userId': userId,
      'movieId': movieId,
      'watchedDate': DateTime.now().toIso8601String(),
    });
  }

  // İzlendi işaretini kaldır
  Future<void> unmarkAsWatched(int userId, int movieId) async {
    final db = await dbHelper.database;
    await db.delete(
      'watched',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
  }

  // Bir film kullanıcı tarafından izlendi mi
  Future<bool> isWatched(int userId, int movieId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'watched',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
    return result.isNotEmpty;
  }

  // Kullanıcının izlediği tüm filmler
  Future<List<Movie>> getWatchedMovies(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT movies.* FROM movies
      INNER JOIN watched ON movies.id = watched.movieId
      WHERE watched.userId = ?
      ORDER BY watched.watchedDate DESC
    ''', [userId]);
    return maps.map((map) => Movie.fromMap(map)).toList();
  }

  // Kullanıcının kaç film izlediği (Profile/Account istatistiği için)
  Future<int> getWatchedCount(int userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM watched WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}