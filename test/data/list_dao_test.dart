import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/list_dao.dart';

void main() {
  late ListDao listDao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    listDao = ListDao();
  });

  tearDownAll(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
  });

  Future<int> insertTestMovie(String title) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('movies', {
      'title': title,
      'posterUrl': 'https://example.com/$title.jpg',
      'director': 'Test Yönetmen',
      'imdbRating': 7.0,
      'badge': null,
      'durationMinutes': 100,
      'releaseYear': 2020,
      'plot': null,
    });
  }

  group('ListDao', () {
    test('createList ile oluşturulan liste getListsForUser ile geliyor', () async {
      await listDao.createList(1, 'Favorilerim', emoji: '❤️', color: '#7C4DFF');

      final lists = await listDao.getListsForUser(1);

      expect(lists.length, 1);
      expect(lists.first.name, 'Favorilerim');
      expect(lists.first.emoji, '❤️');
    });

    test('getListsForUser başka kullanıcının listelerini getirmiyor', () async {
      await listDao.createList(2, 'Kullanıcı 2 Listesi');

      final listsForUser1 = await listDao.getListsForUser(1);

      // Bir önceki testten kalan 'Favorilerim' hariç, kullanıcı 2'ye ait olan görünmemeli
      expect(listsForUser1.any((l) => l.name == 'Kullanıcı 2 Listesi'), isFalse);
    });

    test('updateListDetails liste bilgilerini güncelliyor', () async {
      final listId = await listDao.createList(3, 'Eski İsim');

      await listDao.updateListDetails(listId, name: 'Yeni İsim', emoji: '🎬', description: 'Güncellendi');
      final lists = await listDao.getListsForUser(3);

      expect(lists.first.name, 'Yeni İsim');
      expect(lists.first.emoji, '🎬');
      expect(lists.first.description, 'Güncellendi');
    });

    test('addMovieToList ile eklenen film getMoviesInList ile geliyor', () async {
      final listId = await listDao.createList(4, 'Test Liste');
      final movieId = await insertTestMovie('Film A');

      await listDao.addMovieToList(listId, movieId);
      final movies = await listDao.getMoviesInList(listId);

      expect(movies.length, 1);
      expect(movies.first.title, 'Film A');
    });

    test('removeMovieFromList filmi listeden çıkarıyor', () async {
      final listId = await listDao.createList(5, 'Test Liste 2');
      final movieId = await insertTestMovie('Film B');
      await listDao.addMovieToList(listId, movieId);

      await listDao.removeMovieFromList(listId, movieId);
      final movies = await listDao.getMoviesInList(listId);

      expect(movies, isEmpty);
    });

    test('getMovieCountForList doğru sayıyı döndürüyor', () async {
      final listId = await listDao.createList(6, 'Sayaç Listesi');
      final movieId1 = await insertTestMovie('Film C');
      final movieId2 = await insertTestMovie('Film D');
      await listDao.addMovieToList(listId, movieId1);
      await listDao.addMovieToList(listId, movieId2);

      final count = await listDao.getMovieCountForList(listId);

      expect(count, 2);
    });

    test('getListCount kullanıcının liste sayısını doğru döndürüyor', () async {
      await listDao.createList(7, 'Liste 1');
      await listDao.createList(7, 'Liste 2');

      final count = await listDao.getListCount(7);

      expect(count, 2);
    });

    test('deleteList listeyi ve içindeki list_items kayıtlarını siliyor', () async {
      final listId = await listDao.createList(8, 'Silinecek Liste');
      final movieId = await insertTestMovie('Film E');
      await listDao.addMovieToList(listId, movieId);

      await listDao.deleteList(listId);

      final db = await DatabaseHelper.instance.database;
      final remainingList = await db.query('lists', where: 'id = ?', whereArgs: [listId]);
      final remainingItems = await db.query('list_items', where: 'listId = ?', whereArgs: [listId]);

      expect(remainingList, isEmpty);
      expect(remainingItems, isEmpty);
    });

    test('getListIdsContainingMovie filmin bulunduğu listelerin id\'lerini döndürüyor', () async {
      final listId1 = await listDao.createList(9, 'Liste A');
      final listId2 = await listDao.createList(9, 'Liste B');
      final movieId = await insertTestMovie('Film F');

      await listDao.addMovieToList(listId1, movieId);
      // listId2'ye bilerek eklemiyoruz

      final result = await listDao.getListIdsContainingMovie(9, movieId);

      expect(result, {listId1});
      expect(result.contains(listId2), isFalse);
    });
  });
}