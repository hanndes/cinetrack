// Movie modelinin toMap() / fromMap() dönüşümlerini test eder.
// Bu testler herhangi bir veritabanı veya widget'a ihtiyaç duymaz,
// bu yüzden "unit test" (birim testi) olarak sınıflandırılır.

import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrack_process/models/movie.dart';

void main() {
  group('Movie model', () {
    test('toMap() tüm alanları doğru şekilde eşliyor', () {
      final movie = Movie(
        id: 1,
        title: 'Inception',
        director: 'Christopher Nolan',
        imdbRating: 8.8,
        posterUrl: 'https://example.com/poster.jpg',
        badge: 'Popüler',
        durationMinutes: 148,
        releaseYear: 2010,
        plot: 'Bir hırsız, rüya paylaşım teknolojisiyle sırları çalar.',
        cast: const ['Leonardo DiCaprio'],
        genres: const ['Bilim Kurgu'],
      );

      final map = movie.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Inception');
      expect(map['posterUrl'], 'https://example.com/poster.jpg');
      expect(map['director'], 'Christopher Nolan');
      expect(map['imdbRating'], 8.8);
      expect(map['badge'], 'Popüler');
      expect(map['durationMinutes'], 148);
      expect(map['releaseYear'], 2010);
      expect(map['plot'], 'Bir hırsız, rüya paylaşım teknolojisiyle sırları çalar.');

      // toMap() cast/genres alanlarını içermemeli çünkü bunlar
      // ayrı junction tablolarından (movie_genres, movie_cast) geliyor.
      expect(map.containsKey('cast'), false);
      expect(map.containsKey('genres'), false);
    });

    test('fromMap() zorunlu alanları doğru okuyor', () {
      final map = {
        'id': 5,
        'title': 'Interstellar',
        'posterUrl': 'https://example.com/interstellar.jpg',
        'director': 'Christopher Nolan',
        'imdbRating': 8.6,
        'badge': null,
        'durationMinutes': 169,
        'releaseYear': 2014,
        'plot': null,
      };

      final movie = Movie.fromMap(map);

      expect(movie.id, 5);
      expect(movie.title, 'Interstellar');
      expect(movie.imdbRating, 8.6);
      expect(movie.badge, isNull);
      expect(movie.durationMinutes, 169);
      expect(movie.releaseYear, 2014);
      expect(movie.plot, isNull);

      // genres/cast verilmediğinde boş liste olmalı, null olmamalı.
      expect(movie.genres, isEmpty);
      expect(movie.cast, isEmpty);
    });

    test('fromMap() genres ve cast parametreleri verildiğinde onları kullanıyor', () {
      final map = {
        'id': 2,
        'title': 'The Dark Knight',
        'posterUrl': 'https://example.com/tdk.jpg',
        'director': 'Christopher Nolan',
        'imdbRating': 9.0,
        'badge': null,
        'durationMinutes': 152,
        'releaseYear': 2008,
        'plot': null,
      };

      final movie = Movie.fromMap(
        map,
        genres: const ['Aksiyon', 'Suç'],
        cast: const ['Christian Bale', 'Heath Ledger'],
      );

      expect(movie.genres, ['Aksiyon', 'Suç']);
      expect(movie.cast, ['Christian Bale', 'Heath Ledger']);
    });
  });
}