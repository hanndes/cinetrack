import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/movie_dao.dart';
import 'package:cinetrack_process/models/movie.dart';

// Not: sqflite normalde Android/iOS native koduna ihtiyaç duyar, bu yüzden
// gerçek cihaz/emülatör olmadan test edilemez. sqflite_common_ffi paketi
// SQLite'ı masaüstünde (bu durumda test ortamında) çalıştırmamızı sağlıyor.
// Java/Spring tarafındaki karşılığı: gerçek DB yerine H2/in-memory DB ile
// repository testi yazmak gibi düşünebilirsin.
void main() {
  late MovieDao movieDao;

  setUpAll(() async {
    // sqflite yerine ffi implementasyonunu kullan
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Her test çalıştırmasında temiz bir veritabanıyla başlamak için
    // önceki test veritabanını sil
    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    movieDao = MovieDao();
  });

  tearDownAll(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
  });

  group('MovieDao', () {
    test('insertMovie ile eklenen film getMovieById ile geri geliyor', () async {
      final movie = Movie(
        title: 'Test Filmi',
        director: 'Test Yönetmen',
        imdbRating: 7.5,
        posterUrl: 'https://example.com/test.jpg',
        durationMinutes: 100,
        releaseYear: 2020,
      );

      final id = await movieDao.insertMovie(movie);
      final fetched = await movieDao.getMovieById(id);

      expect(fetched, isNotNull);
      expect(fetched!.title, 'Test Filmi');
      expect(fetched.releaseYear, 2020);
    });

    test('searchMovies başlıkta kısmi eşleşme buluyor', () async {
      await movieDao.insertMovie(Movie(
        title: 'The Dark Knight',
        director: 'Christopher Nolan',
        imdbRating: 9.0,
        posterUrl: 'https://example.com/tdk.jpg',
        durationMinutes: 152,
        releaseYear: 2008,
      ));

      final results = await movieDao.searchMovies('Dark');

      expect(results, isNotEmpty);
      expect(results.any((m) => m.title == 'The Dark Knight'), isTrue);
    });

    test('searchMovies eşleşme yoksa boş liste döner', () async {
      final results = await movieDao.searchMovies('BulunmayacakBirBaslik123');

      expect(results, isEmpty);
    });

    test('addGenreToMovie ile eklenen tür getMovieById sonucunda görünüyor', () async {
      final id = await movieDao.insertMovie(Movie(
        title: 'Genre Test Filmi',
        director: 'Yönetmen',
        imdbRating: 6.0,
        posterUrl: 'https://example.com/genre.jpg',
        durationMinutes: 90,
        releaseYear: 2019,
      ));

      await movieDao.addGenreToMovie(id, 'Drama');
      final fetched = await movieDao.getMovieById(id);

      expect(fetched!.genres, contains('Drama'));
    });

    test('aynı genre adı tekrar eklendiğinde genres tablosunda yinelenmiyor', () async {
      final id1 = await movieDao.insertMovie(Movie(
        title: 'Film A',
        director: 'Yönetmen A',
        imdbRating: 6.5,
        posterUrl: 'https://example.com/a.jpg',
        durationMinutes: 95,
        releaseYear: 2021,
      ));
      final id2 = await movieDao.insertMovie(Movie(
        title: 'Film B',
        director: 'Yönetmen B',
        imdbRating: 7.0,
        posterUrl: 'https://example.com/b.jpg',
        durationMinutes: 105,
        releaseYear: 2022,
      ));

      await movieDao.addGenreToMovie(id1, 'Komedi');
      await movieDao.addGenreToMovie(id2, 'Komedi');

      final db = await DatabaseHelper.instance.database;
      final genreRows = await db.query('genres', where: 'name = ?', whereArgs: ['Komedi']);

      // İki farklı filme aynı tür eklendi ama genres tablosunda tek satır olmalı
      expect(genreRows.length, 1);
    });
  });
}