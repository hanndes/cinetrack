import '../models/review.dart';
import 'database_helper.dart';

class ReviewDao {
  final dbHelper = DatabaseHelper.instance;

  // Yorum ekle
  Future<int> addReview(int userId, int movieId, double rating, String? reviewText) async {
    final db = await dbHelper.database;
    return await db.insert('reviews', {
      'userId': userId,
      'movieId': movieId,
      'rating': rating,
      'reviewText': reviewText,
      'reviewDate': DateTime.now().toIso8601String(),
    });
  }

  // Bir filme ait tüm yorumları getir (en yeni üstte, kullanıcı adıyla birlikte)
  Future<List<Review>> getReviewsForMovie(int movieId) async {
    final db = await dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT reviews.*, users.name as userName
      FROM reviews
      INNER JOIN users ON reviews.userId = users.id
      WHERE reviews.movieId = ?
      ORDER BY reviews.reviewDate DESC
    ''', [movieId]);
    return maps.map((map) => Review.fromMap(map)).toList();
  }

  // Bir filmin ortalama puanı
  Future<double?> getAverageRating(int movieId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(rating) as avgRating FROM reviews WHERE movieId = ?',
      [movieId],
    );
    final avg = result.first['avgRating'];
    return avg == null ? null : (avg as num).toDouble();
  }

  // Yorum sil (sadece kendi yorumunu silebilmesi için userId kontrolü de eklendi)
  Future<void> deleteReview(int reviewId, int userId) async {
    final db = await dbHelper.database;
    await db.delete(
      'reviews',
      where: 'id = ? AND userId = ?',
      whereArgs: [reviewId, userId],
    );
  }

  // Yorum güncelle (sadece kendi yorumunu güncelleyebilmesi için userId kontrolü de eklendi)
  Future<void> updateReview(int reviewId, int userId, double rating, String? reviewText) async {
    final db = await dbHelper.database;
    await db.update(
      'reviews',
      {
        'rating': rating,
        'reviewText': reviewText,
        'reviewDate': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [reviewId, userId],
    );
  }

  // Kullanıcının toplam kaç yorum yazdığını getir (Account/Profile istatistiği için)
  Future<int> getReviewCountForUser(int userId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reviews WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int;
  }
}