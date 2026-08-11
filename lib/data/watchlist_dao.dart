import '../models/movie.dart';
import 'database_helper.dart';

class WatchlistDao {
  final dbHelper = DatabaseHelper.instance;

  // Watchlist'e film ekle
  Future<void> addToWatchlist(int userId, int movieId) async {
    final db = await dbHelper.database;
    final already = await isInWatchlist(userId, movieId);
    if (!already) {
      await db.insert('watchlist', {
        'userId': userId,
        'movieId': movieId,
      });
    }
  }

  // Watchlist'ten film çıkar
  Future<void> removeFromWatchlist(int userId, int movieId) async {
    final db = await dbHelper.database;
    await db.delete(
      'watchlist',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
  }

  // Film watchlist'te mi kontrol et
  Future<bool> isInWatchlist(int userId, int movieId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'watchlist',
      where: 'userId = ? AND movieId = ?',
      whereArgs: [userId, movieId],
    );
    return result.isNotEmpty;
  }

  // Kullanıcının watchlist'indeki tüm filmleri getir (JOIN ile)
  Future<List<Movie>> getWatchlistMovies(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT movies.* FROM movies
      INNER JOIN watchlist ON movies.id = watchlist.movieId
      WHERE watchlist.userId = ?
    ''', [userId]);
    return maps.map((map) => Movie.fromMap(map)).toList();
  }

  // Kullanıcının watchlist'inde kaç film olduğunu getir (istatistik kartı için)
  Future<int> getWatchlistCount(int userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM watchlist WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}