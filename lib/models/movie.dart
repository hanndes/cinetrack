class Movie {
  final int? id;
  final String title;
  final String director;
  final double imdbRating;
  final String posterUrl;
  final String? badge;
  final int durationMinutes;
  final int releaseYear;
  final String? plot;
  final List<String> cast;
  final List<String> genres;

  Movie({
    this.id,
    required this.title,
    required this.director,
    required this.imdbRating,
    required this.posterUrl,
    this.badge,
    required this.durationMinutes,
    required this.releaseYear,
    this.plot,
    this.cast = const [],
    this.genres = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poster_url': posterUrl,
      'director': director,
      'imdb_rating': imdbRating,
      'badge': badge,
      'duration_minutes': durationMinutes,
      'release_year': releaseYear,
      'plot': plot,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map, {List<String>? genres, List<String>? cast}) {
    return Movie(
      id: map['id'],
      title: map['title'],
      posterUrl: map['poster_url'],
      director: map['director'],
      imdbRating: (map['imdb_rating'] as num).toDouble(),
      badge: map['badge'],
      durationMinutes: map['duration_minutes'],
      releaseYear: map['release_year'],
      plot: map['plot'],
      genres: genres ?? const [],
      cast: cast ?? const [],
    );
  }
}