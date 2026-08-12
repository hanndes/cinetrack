import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/review_dao.dart';

void main() {
  late ReviewDao reviewDao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    reviewDao = ReviewDao();
  });

  tearDownAll(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
  });

  // getReviewsForMovie sorgusu users tablosuyla INNER JOIN yaptığı için
  // testlerde gerçek bir kullanıcı satırı olması gerekiyor.
  Future<int> insertTestUser(String name, String email) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('users', {
      'name': name,
      'email': email,
      'passwordHash': 'dummyhash',
      'profileImageUrl': null,
    });
  }

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

  group('ReviewDao', () {
    test('addReview ile eklenen yorum getReviewsForMovie ile geliyor ve userName JOIN\'den doluyor', () async {
      final userId = await insertTestUser('Hande', 'hande.review@example.com');
      final movieId = await insertTestMovie('Film A');

      await reviewDao.addReview(userId, movieId, 9.0, 'Harika bir film');
      final reviews = await reviewDao.getReviewsForMovie(movieId);

      expect(reviews.length, 1);
      expect(reviews.first.userName, 'Hande');
      expect(reviews.first.rating, 9.0);
    });

    test('getReviewsForMovie farklı filmin yorumlarını karıştırmıyor', () async {
      final userId = await insertTestUser('Ali', 'ali.review@example.com');
      final movieId1 = await insertTestMovie('Film B');
      final movieId2 = await insertTestMovie('Film C');

      await reviewDao.addReview(userId, movieId1, 7.0, 'B için yorum');
      await reviewDao.addReview(userId, movieId2, 8.0, 'C için yorum');

      final reviewsForB = await reviewDao.getReviewsForMovie(movieId1);

      expect(reviewsForB.length, 1);
      expect(reviewsForB.first.reviewText, 'B için yorum');
    });

    test('getAverageRating birden fazla yorumun ortalamasını doğru hesaplıyor', () async {
      final user1 = await insertTestUser('User1', 'user1.avg@example.com');
      final user2 = await insertTestUser('User2', 'user2.avg@example.com');
      final movieId = await insertTestMovie('Film D');

      await reviewDao.addReview(user1, movieId, 8.0, null);
      await reviewDao.addReview(user2, movieId, 6.0, null);

      final avg = await reviewDao.getAverageRating(movieId);

      expect(avg, 7.0);
    });

    test('getAverageRating hiç yorum yoksa null döner', () async {
      final movieId = await insertTestMovie('Film E');

      final avg = await reviewDao.getAverageRating(movieId);

      expect(avg, isNull);
    });

    test('deleteReview sadece yorumun sahibiyse siliyor', () async {
      final owner = await insertTestUser('Sahip', 'sahip@example.com');
      final other = await insertTestUser('Baskasi', 'baskasi@example.com');
      final movieId = await insertTestMovie('Film F');

      final reviewId = await reviewDao.addReview(owner, movieId, 5.0, 'Silinecek yorum');

      // Başka bir kullanıcı silmeye çalışıyor -> silinmemeli
      await reviewDao.deleteReview(reviewId, other);
      var reviews = await reviewDao.getReviewsForMovie(movieId);
      expect(reviews.length, 1);

      // Gerçek sahibi siliyor -> silinmeli
      await reviewDao.deleteReview(reviewId, owner);
      reviews = await reviewDao.getReviewsForMovie(movieId);
      expect(reviews, isEmpty);
    });

    test('updateReview sadece yorumun sahibiyse güncelliyor', () async {
      final owner = await insertTestUser('Sahip2', 'sahip2@example.com');
      final other = await insertTestUser('Baskasi2', 'baskasi2@example.com');
      final movieId = await insertTestMovie('Film G');

      final reviewId = await reviewDao.addReview(owner, movieId, 4.0, 'Eski yorum');

      // Başkası güncellemeye çalışıyor -> değişmemeli
      await reviewDao.updateReview(reviewId, other, 10.0, 'Sahte güncelleme');
      var reviews = await reviewDao.getReviewsForMovie(movieId);
      expect(reviews.first.rating, 4.0);

      // Gerçek sahibi güncelliyor -> değişmeli
      await reviewDao.updateReview(reviewId, owner, 9.0, 'Güncellenmiş yorum');
      reviews = await reviewDao.getReviewsForMovie(movieId);
      expect(reviews.first.rating, 9.0);
      expect(reviews.first.reviewText, 'Güncellenmiş yorum');
    });

    test('getReviewCountForUser doğru sayıyı döndürüyor', () async {
      final userId = await insertTestUser('Sayac', 'sayac@example.com');
      final movieId1 = await insertTestMovie('Film H');
      final movieId2 = await insertTestMovie('Film I');

      await reviewDao.addReview(userId, movieId1, 6.0, null);
      await reviewDao.addReview(userId, movieId2, 7.0, null);

      final count = await reviewDao.getReviewCountForUser(userId);

      expect(count, 2);
    });
  });
}