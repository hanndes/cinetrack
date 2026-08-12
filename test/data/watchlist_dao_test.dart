import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/watchlist_dao.dart';

void main() {
  late WatchlistDao watchlistDao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    watchlistDao = WatchlistDao();
  });

  tearDownAll(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
  });

  // Testlerde kullanacağımız bir film ekleyip id'sini döndüren yardımcı fonksiyon
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

  group('WatchlistDao', () {
    test('addToWatchlist ile eklenen film isInWatchlist ile doğrulanıyor', () async {
      final movieId = await insertTestMovie('Film A');

      await watchlistDao.addToWatchlist(1, movieId);
      final result = await watchlistDao.isInWatchlist(1, movieId);

      expect(result, isTrue);
    });

    test('isInWatchlist eklenmemiş film için false döner', () async {
      final movieId = await insertTestMovie('Film B');

      final result = await watchlistDao.isInWatchlist(1, movieId);

      expect(result, isFalse);
    });

    test('addToWatchlist aynı film iki kez eklenirse yinelenmiyor', () async {
      final movieId = await insertTestMovie('Film C');

      await watchlistDao.addToWatchlist(2, movieId);
      await watchlistDao.addToWatchlist(2, movieId);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'watchlist',
        where: 'userId = ? AND movieId = ?',
        whereArgs: [2, movieId],
      );

      expect(rows.length, 1);
    });

    test('removeFromWatchlist filmi listeden çıkarıyor', () async {
      final movieId = await insertTestMovie('Film D');
      await watchlistDao.addToWatchlist(3, movieId);

      await watchlistDao.removeFromWatchlist(3, movieId);
      final result = await watchlistDao.isInWatchlist(3, movieId);

      expect(result, isFalse);
    });

    test('getWatchlistMovies kullanıcının filmlerini JOIN ile getiriyor', () async {
      final movieId1 = await insertTestMovie('Film E');
      final movieId2 = await insertTestMovie('Film F');
      await watchlistDao.addToWatchlist(4, movieId1);
      await watchlistDao.addToWatchlist(4, movieId2);

      final movies = await watchlistDao.getWatchlistMovies(4);

      expect(movies.length, 2);
      expect(movies.map((m) => m.title), containsAll(['Film E', 'Film F']));
    });

    test('getWatchlistMovies başka kullanıcının filmlerini getirmiyor', () async {
      final movieId = await insertTestMovie('Film G');
      await watchlistDao.addToWatchlist(5, movieId);

      final movies = await watchlistDao.getWatchlistMovies(999);

      expect(movies, isEmpty);
    });

    test('getWatchlistCount doğru sayıyı döndürüyor', () async {
      final movieId1 = await insertTestMovie('Film H');
      final movieId2 = await insertTestMovie('Film I');
      await watchlistDao.addToWatchlist(6, movieId1);
      await watchlistDao.addToWatchlist(6, movieId2);

      final count = await watchlistDao.getWatchlistCount(6);

      expect(count, 2);
    });

    test('getWatchlistCount hiç film yoksa 0 döndürüyor', () async {
      final count = await watchlistDao.getWatchlistCount(777);

      expect(count, 0);
    });
  });
}