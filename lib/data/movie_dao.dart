import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/movie.dart';

class MovieDao {
  final supabase = Supabase.instance.client;

  // Bir filmin türlerini getir
  Future<List<String>> _getGenresForMovie(int movieId) async {
    final maps = await supabase
        .from('movie_genres')
        .select('genres(name)')
        .eq('movie_id', movieId);
    return maps.map((map) => map['genres']['name'] as String).toList();
  }

  // Bir filmin oyuncularını getir
  Future<List<String>> _getCastForMovie(int movieId) async {
    final maps = await supabase
        .from('movie_cast')
        .select('artists(name)')
        .eq('movie_id', movieId);
    return maps.map((map) => map['artists']['name'] as String).toList();
  }

  // Bir map'i, genres/cast bilgisiyle birlikte Movie'ye çevir
  Future<Movie> _mapToMovieWithDetails(Map<String, dynamic> map) async {
    final movieId = map['id'] as int;
    final genres = await _getGenresForMovie(movieId);
    final cast = await _getCastForMovie(movieId);
    return Movie.fromMap(map, genres: genres, cast: cast);
  }

  // Tek film ekle
  Future<int> insertMovie(Movie movie) async {
    final response = await supabase
        .from('movies')
        .insert(movie.toMap()..remove('id'))
        .select('id')
        .single();
    return response['id'] as int;
  }

  // Tüm filmleri getir (genres/cast dahil)
  Future<List<Movie>> getAllMovies() async {
    final maps = await supabase.from('movies').select();
    final movies = <Movie>[];
    for (final map in maps) {
      movies.add(await _mapToMovieWithDetails(map));
    }
    return movies;
  }

  // ID ile tek film getir (genres/cast dahil)
  Future<Movie?> getMovieById(int id) async {
    final maps = await supabase.from('movies').select().eq('id', id);
    if (maps.isNotEmpty) {
      return await _mapToMovieWithDetails(maps.first);
    }
    return null;
  }

  // Film adına göre ara
  Future<List<Movie>> searchMovies(String query) async {
    final maps = await supabase.from('movies').select().ilike('title', '%$query%');
    final movies = <Movie>[];
    for (final map in maps) {
      movies.add(await _mapToMovieWithDetails(map));
    }
    return movies;
  }

  // Bir filme tür ekle (genre yoksa oluşturur)
  Future<void> addGenreToMovie(int movieId, String genreName) async {
    final existing = await supabase.from('genres').select().eq('name', genreName);
    int genreId;
    if (existing.isNotEmpty) {
      genreId = existing.first['id'] as int;
    } else {
      final inserted =
      await supabase.from('genres').insert({'name': genreName}).select('id').single();
      genreId = inserted['id'] as int;
    }

    await supabase.from('movie_genres').insert({'movie_id': movieId, 'genre_id': genreId});
  }

  // Bir filme oyuncu ekle (artist yoksa oluşturur)
  Future<void> addCastToMovie(int movieId, String artistName) async {
    final existing = await supabase.from('artists').select().eq('name', artistName);
    int artistId;
    if (existing.isNotEmpty) {
      artistId = existing.first['id'] as int;
    } else {
      final inserted =
      await supabase.from('artists').insert({'name': artistName}).select('id').single();
      artistId = inserted['id'] as int;
    }

    await supabase.from('movie_cast').insert({'movie_id': movieId, 'artist_id': artistId});
  }

  // Tablo boş mu kontrol et (seed işlemi için)
  Future<bool> isEmpty() async {
    final result = await supabase.from('movies').select('id').limit(1);
    return result.isEmpty;
  }

  // Veritabanı boşsa dummy filmleri ekle (genres/cast dahil)
  Future<void> seedMoviesIfEmpty(List<Movie> movies) async {
    final empty = await isEmpty();
    if (empty) {
      for (final movie in movies) {
        final movieId = await insertMovie(movie);
        for (final genre in movie.genres) {
          await addGenreToMovie(movieId, genre);
        }
        for (final actor in movie.cast) {
          await addCastToMovie(movieId, actor);
        }
      }
    }
  }
}