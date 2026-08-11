import '../models/movie.dart';
import '../models/movie_list.dart';
import 'database_helper.dart';

class ListDao {
  final dbHelper = DatabaseHelper.instance;

  // Yeni liste oluştur
  Future<int> createList(
      int userId,
      String name, {
        String? emoji,
        String? color,
        String? description,
      }) async {
    final db = await dbHelper.database;
    return await db.insert('lists', {
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'color': color,
      'description': description,
      'createdDate': DateTime.now().toIso8601String(),
    });
  }

  // Liste bilgilerini güncelle
  Future<void> updateListDetails(
      int listId, {
        required String name,
        String? emoji,
        String? color,
        String? description,
      }) async {
    final db = await dbHelper.database;
    await db.update(
      'lists',
      {
        'name': name,
        'emoji': emoji,
        'color': color,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  // Kullanıcının tüm listelerini getir
  Future<List<MovieList>> getListsForUser(int userId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'lists',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => MovieList.fromMap(map)).toList();
  }

  // Listeye film ekle
  Future<void> addMovieToList(int listId, int movieId) async {
    final db = await dbHelper.database;
    await db.insert('list_items', {
      'listId': listId,
      'movieId': movieId,
    });
  }

  // Listeden film çıkar
  Future<void> removeMovieFromList(int listId, int movieId) async {
    final db = await dbHelper.database;
    await db.delete(
      'list_items',
      where: 'listId = ? AND movieId = ?',
      whereArgs: [listId, movieId],
    );
  }

  // Bir listedeki filmleri getir
  Future<List<Movie>> getMoviesInList(int listId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT movies.* FROM movies
      INNER JOIN list_items ON movies.id = list_items.movieId
      WHERE list_items.listId = ?
    ''', [listId]);
    return maps.map((map) => Movie.fromMap(map)).toList();
  }

  // Bir listede kaç film olduğunu getir (liste kartında göstermek için)
  Future<int> getMovieCountForList(int listId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM list_items WHERE listId = ?',
      [listId],
    );
    return result.first['count'] as int;
  }

  // Kullanıcının kaç listesi var (Profile ekranı için)
  Future<int> getListCount(int userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lists WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int;
  }

  // Listeyi sil
  Future<void> deleteList(int listId) async {
    final db = await dbHelper.database;
    await db.delete('list_items', where: 'listId = ?', whereArgs: [listId]);
    await db.delete('lists', where: 'id = ?', whereArgs: [listId]);
  }

  // Bir filmin, kullanıcının hangi listelerinde olduğunu getir
  // (Listeye Ekle bottom sheet'inde hangi checkbox'ların işaretli
  // gösterileceğini belirlemek için kullanılır)
  Future<Set<int>> getListIdsContainingMovie(int userId, int movieId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT lists.id FROM lists
      INNER JOIN list_items ON lists.id = list_items.listId
      WHERE lists.userId = ? AND list_items.movieId = ?
    ''', [userId, movieId]);
    return maps.map((map) => map['id'] as int).toSet();
  }
}