import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrack_process/models/review.dart';

void main() {
  group('Review modeli', () {
    test('fromMap rating alanını int geldiğinde de double\'a çeviriyor', () {
      // SQLite bazen REAL sütunları tam sayıysa int olarak döndürebilir,
      // bu yüzden fromMap içindeki (map['rating'] as num).toDouble() kritik.
      final map = {
        'id': 1,
        'userId': 1,
        'movieId': 1,
        'rating': 8, // int olarak geldi
        'reviewText': 'Harika bir film',
        'reviewDate': '2026-08-01',
        'userName': 'Hande',
      };

      final review = Review.fromMap(map);

      expect(review.rating, 8.0);
      expect(review.rating, isA<double>());
    });

    test('toMap userName alanını içermiyor (JOIN sonucu, tabloya ait değil)', () {
      final review = Review(
        userId: 1,
        movieId: 2,
        rating: 9.5,
        reviewText: 'Süper',
        userName: 'Hande',
      );

      final map = review.toMap();

      expect(map.containsKey('userName'), isFalse);
      expect(map['rating'], 9.5);
    });

    test('reviewText ve reviewDate opsiyonel, null olabilir', () {
      final review = Review(userId: 1, movieId: 1, rating: 7.0);

      expect(review.reviewText, isNull);
      expect(review.reviewDate, isNull);
      expect(review.userName, isNull);
    });
  });
}