import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/watched_dao.dart';

void main() {
  late WatchedDao watchedDao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    watchedDao = WatchedDao();
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

  group('WatchedDao', () {
    test('markAsWatched ile işaretlenen film isWatched ile doğrulanıyor', () async {
      final movieId = await insertTestMovie('Film A');

      await watchedDao.markAsWatched(1, movieId);
      final result = await watchedDao.isWatched(1, movieId);

      expect(result, isTrue);
    });

    test('isWatched işaretlenmemiş film için false döner', () async {
      final movieId = await insertTestMovie('Film B');

      final result = await watchedDao.isWatched(1, movieId);

      expect(result, isFalse);
    });

    test('markAsWatched aynı film iki kez işaretlenirse yinelenmiyor', () async {
      final movieId = await insertTestMovie('Film C');

      await watchedDao.markAsWatched(2, movieId);
      await watchedDao.markAsWatched(2, movieId);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'watched',
        where: 'userId = ? AND movieId = ?',
        whereArgs: [2, movieId],
      );

      expect(rows.length, 1);
    });

    test('unmarkAsWatched işareti kaldırıyor', () async {
      final movieId = await insertTestMovie('Film D');
      await watchedDao.markAsWatched(3, movieId);

      await watchedDao.unmarkAsWatched(3, movieId);
      final result = await watchedDao.isWatched(3, movieId);

      expect(result, isFalse);
    });

    test('getWatchedMovies kullanıcının izlediği filmleri JOIN ile getiriyor', () async {
      final movieId1 = await insertTestMovie('Film E');
      final movieId2 = await insertTestMovie('Film F');
      await watchedDao.markAsWatched(4, movieId1);
      await watchedDao.markAsWatched(4, movieId2);

      final movies = await watchedDao.getWatchedMovies(4);

      expect(movies.length, 2);
      expect(movies.map((m) => m.title), containsAll(['Film E', 'Film F']));
    });

    test('getWatchedMovies başka kullanıcının filmlerini getirmiyor', () async {
      final movieId = await insertTestMovie('Film G');
      await watchedDao.markAsWatched(5, movieId);

      final movies = await watchedDao.getWatchedMovies(999);

      expect(movies, isEmpty);
    });

    test('getWatchedCount doğru sayıyı döndürüyor', () async {
      final movieId1 = await insertTestMovie('Film H');
      final movieId2 = await insertTestMovie('Film I');
      await watchedDao.markAsWatched(6, movieId1);
      await watchedDao.markAsWatched(6, movieId2);

      final count = await watchedDao.getWatchedCount(6);

      expect(count, 2);
    });

    test('getWatchedCount hiç film yoksa 0 döndürüyor', () async {
      final count = await watchedDao.getWatchedCount(888);

      expect(count, 0);
    });
  });
}