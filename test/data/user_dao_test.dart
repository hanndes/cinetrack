import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cinetrack_process/data/database_helper.dart';
import 'package:cinetrack_process/data/user_dao.dart';

// Not: Her test dosyası ayrı bir Dart isolate'inde çalıştığı için
// DatabaseHelper singleton'ı movie_dao_test.dart ile çakışmıyor,
// ama yine de temiz bir DB dosyasıyla başlamak için setUpAll'da siliyoruz.
void main() {
  late UserDao userDao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase('$dbPath/cinetrack.db');
  });

  setUp(() {
    userDao = UserDao();
  });

  tearDownAll(() async {
    final db = await DatabaseHelper.instance.database;
    await db.close();
  });

  group('UserDao', () {
    test('register şifreyi düz metin olarak değil, hash olarak saklıyor', () async {
      final user = await userDao.register('Hande', 'hande@example.com', 'sifre123');

      expect(user.passwordHash, isNot('sifre123'));
      // bcrypt hash'leri her zaman $2 ile başlar
      expect(user.passwordHash, startsWith(r'$2'));
    });

    test('getUserByEmail kayıtlı kullanıcıyı buluyor', () async {
      await userDao.register('Ali', 'ali@example.com', 'parola456');

      final found = await userDao.getUserByEmail('ali@example.com');

      expect(found, isNotNull);
      expect(found!.name, 'Ali');
    });

    test('getUserByEmail kayıtlı olmayan email için null dönüyor', () async {
      final found = await userDao.getUserByEmail('yokboyle@example.com');

      expect(found, isNull);
    });

    test('login doğru şifreyle kullanıcıyı döndürüyor', () async {
      await userDao.register('Ayse', 'ayse@example.com', 'dogrusifre');

      final result = await userDao.login('ayse@example.com', 'dogrusifre');

      expect(result, isNotNull);
      expect(result!.email, 'ayse@example.com');
    });

    test('login yanlış şifreyle null dönüyor', () async {
      await userDao.register('Mehmet', 'mehmet@example.com', 'gercekSifre');

      final result = await userDao.login('mehmet@example.com', 'yanlisSifre');

      expect(result, isNull);
    });

    test('login kayıtlı olmayan email için null dönüyor', () async {
      final result = await userDao.login('boyle@biri.yok', 'herhangi');

      expect(result, isNull);
    });

    test('updateProfile isim ve email\'i güncelliyor', () async {
      final user = await userDao.register('Eski İsim', 'eski@example.com', 'sifre');

      await userDao.updateProfile(user.id!, 'Yeni İsim', 'yeni@example.com');
      final updated = await userDao.getUserByEmail('yeni@example.com');

      expect(updated, isNotNull);
      expect(updated!.name, 'Yeni İsim');
    });

    test('changePassword mevcut şifre yanlışsa false döner ve şifreyi değiştirmez', () async {
      final user = await userDao.register('Test', 'changepass1@example.com', 'orijinalSifre');

      final result = await userDao.changePassword(user.id!, 'yanlisSifre', 'yeniSifre');

      expect(result, isFalse);
      // Eski şifreyle hâlâ giriş yapılabiliyor olmalı
      final stillLogsIn = await userDao.login('changepass1@example.com', 'orijinalSifre');
      expect(stillLogsIn, isNotNull);
    });

    test('changePassword mevcut şifre doğruysa true döner ve şifreyi günceller', () async {
      final user = await userDao.register('Test2', 'changepass2@example.com', 'eskiSifre');

      final result = await userDao.changePassword(user.id!, 'eskiSifre', 'yeniSifre');

      expect(result, isTrue);
      final loginWithOld = await userDao.login('changepass2@example.com', 'eskiSifre');
      final loginWithNew = await userDao.login('changepass2@example.com', 'yeniSifre');
      expect(loginWithOld, isNull);
      expect(loginWithNew, isNotNull);
    });

    test('deleteAccount kullanıcıyı ve ilişkili verileri siliyor', () async {
      final user = await userDao.register('Silinecek', 'silinecek@example.com', 'sifre');
      final db = await DatabaseHelper.instance.database;

      // İlişkili bazı kayıtlar ekleyelim (movieId gerçek olmasa da FK zorunlu değil)
      await db.insert('watchlist', {'userId': user.id, 'movieId': 1});
      await db.insert('reviews', {
        'userId': user.id,
        'movieId': 1,
        'rating': 8.0,
        'reviewText': 'test',
        'reviewDate': '2026-01-01',
      });
      final listId = await db.insert('lists', {'userId': user.id, 'name': 'Test Liste'});
      await db.insert('list_items', {'listId': listId, 'movieId': 1});

      await userDao.deleteAccount(user.id!);

      final deletedUser = await userDao.getUserByEmail('silinecek@example.com');
      final remainingWatchlist = await db.query('watchlist', where: 'userId = ?', whereArgs: [user.id]);
      final remainingReviews = await db.query('reviews', where: 'userId = ?', whereArgs: [user.id]);
      final remainingLists = await db.query('lists', where: 'userId = ?', whereArgs: [user.id]);
      final remainingListItems = await db.query('list_items', where: 'listId = ?', whereArgs: [listId]);

      expect(deletedUser, isNull);
      expect(remainingWatchlist, isEmpty);
      expect(remainingReviews, isEmpty);
      expect(remainingLists, isEmpty);
      expect(remainingListItems, isEmpty);
    });
  });
}