import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/movie.dart';

class WatchlistDao {
  final supabase = Supabase.instance.client;

  // Watchlist'e film ekle
  Future<void> addToWatchlist(int userId, int movieId) async {
    final already = await isInWatchlist(userId, movieId);
    if (!already) {
      await supabase.from('watchlist').insert({
        'user_id': userId,
        'movie_id': movieId,
      });
    }
  }

  // Watchlist'ten film çıkar
  Future<void> removeFromWatchlist(int userId, int movieId) async {
    await supabase.from('watchlist').delete().eq('user_id', userId).eq('movie_id', movieId);
  }

  // Film watchlist'te mi kontrol et
  Future<bool> isInWatchlist(int userId, int movieId) async {
    final result = await supabase
        .from('watchlist')
        .select('id')
        .eq('user_id', userId)
        .eq('movie_id', movieId);
    return result.isNotEmpty;
  }

  // Kullanıcının watchlist'indeki tüm filmleri getir
  Future<List<Movie>> getWatchlistMovies(int userId) async {
    final maps = await supabase
        .from('watchlist')
        .select('movies(*)')
        .eq('user_id', userId);
    return maps.map((map) => Movie.fromMap(map['movies'])).toList();
  }

  // Kullanıcının watchlist'inde kaç film olduğunu getir
  Future<int> getWatchlistCount(int userId) async {
    final response = await supabase
        .from('watchlist')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return response.count;
  }
}