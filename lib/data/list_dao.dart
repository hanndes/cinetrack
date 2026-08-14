import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/movie.dart';
import '../models/movie_list.dart';

class ListDao {
  final supabase = Supabase.instance.client;

  // Yeni liste oluştur
  Future<int> createList(
      int userId,
      String name, {
        String? emoji,
        String? color,
        String? description,
      }) async {
    final response = await supabase.from('lists').insert({
      'user_id': userId,
      'name': name,
      'emoji': emoji,
      'color': color,
      'description': description,
      'created_date': DateTime.now().toIso8601String(),
    }).select('id').single();
    return response['id'] as int;
  }

  // Liste bilgilerini güncelle
  Future<void> updateListDetails(
      int listId, {
        required String name,
        String? emoji,
        String? color,
        String? description,
      }) async {
    await supabase.from('lists').update({
      'name': name,
      'emoji': emoji,
      'color': color,
      'description': description,
    }).eq('id', listId);
  }

  // Tek bir listeyi id ile getir
  Future<MovieList?> getListById(int listId) async {
    final maps = await supabase.from('lists').select().eq('id', listId);
    if (maps.isEmpty) return null;
    return MovieList.fromMap(maps.first);
  }

  // Kullanıcının tüm listelerini getir
  Future<List<MovieList>> getListsForUser(int userId) async {
    final maps = await supabase.from('lists').select().eq('user_id', userId);
    return maps.map((map) => MovieList.fromMap(map)).toList();
  }

  // Listeye film ekle
  Future<void> addMovieToList(int listId, int movieId) async {
    await supabase.from('list_items').insert({
      'list_id': listId,
      'movie_id': movieId,
    });
  }

  // Listeden film çıkar
  Future<void> removeMovieFromList(int listId, int movieId) async {
    await supabase
        .from('list_items')
        .delete()
        .eq('list_id', listId)
        .eq('movie_id', movieId);
  }

  // Bir listedeki filmleri getir
  Future<List<Movie>> getMoviesInList(int listId) async {
    final maps = await supabase
        .from('list_items')
        .select('movies(*)')
        .eq('list_id', listId);
    return maps.map((map) => Movie.fromMap(map['movies'])).toList();
  }

  // Bir listede kaç film olduğunu getir
  Future<int> getMovieCountForList(int listId) async {
    final response = await supabase
        .from('list_items')
        .select('id')
        .eq('list_id', listId)
        .count(CountOption.exact);
    return response.count;
  }

  // Kullanıcının kaç listesi var
  Future<int> getListCount(int userId) async {
    final response = await supabase
        .from('lists')
        .select('id')
        .eq('user_id', userId)
        .count(CountOption.exact);
    return response.count;
  }

  // Listeyi sil
  Future<void> deleteList(int listId) async {
    await supabase.from('list_items').delete().eq('list_id', listId);
    await supabase.from('lists').delete().eq('id', listId);
  }

  // Bir filmin, kullanıcının hangi listelerinde olduğunu getir
  Future<Set<int>> getListIdsContainingMovie(int userId, int movieId) async {
    final maps = await supabase
        .from('list_items')
        .select('list_id, lists!inner(user_id)')
        .eq('movie_id', movieId)
        .eq('lists.user_id', userId);
    return maps.map((map) => map['list_id'] as int).toSet();
  }
}