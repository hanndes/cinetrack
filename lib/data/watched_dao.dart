import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/movie.dart';

class WatchedDao {
  final supabase = Supabase.instance.client;

  // Filmi izlendi olarak işaretle
  Future<void> markAsWatched(int userId, int movieId) async {
    final existing = await supabase
        .from('watched')
        .select('id')
        .eq('user_id', userId)
        .eq('movie_id', movieId);
    if (existing.isNotEmpty) return;

    await supabase.from('watched').insert({
      'user_id': userId,
      'movie_id': movieId,
      'watched_date': DateTime.now().toIso8601String(),
    });
  }

  // İzlendi işaretini kaldır
  Future<void> unmarkAsWatched(int userId, int movieId) async {
    await supabase.from('watched').delete().eq('user_id', userId).eq('movie_id', movieId);
  }

  // Bir film kullanıcı tarafından izlendi mi
  Future<bool> isWatched(int userId, int movieId) async {
    final result = await supabase
        .from('watched')
        .select('id')
        .eq('user_id', userId)
        .eq('movie_id', movieId);
    return result.isNotEmpty;
  }

  // Kullanıcının izlediği tüm filmler
  Future<List<Movie>> getWatchedMovies(int userId) async {
    final maps = await supabase
        .from('watched')
        .select('movies(*)')
        .eq('user_id', userId)
        .order('watched_date', ascending: false);
    return maps.map((map) => Movie.fromMap(map['movies'])).toList();
  }

  // Kullanıcının kaç film izlediği (Profile/Account istatistiği için)
  Future<int> getWatchedCount(int userId) async {
    final response = await supabase
        .from('watched')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return response.count;
  }
}