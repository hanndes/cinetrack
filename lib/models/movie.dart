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
      'posterUrl': posterUrl,
      'director': director,
      'imdbRating': imdbRating,
      'badge': badge,
      'durationMinutes': durationMinutes,
      'releaseYear': releaseYear,
      'plot': plot,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map, {List<String>? genres, List<String>? cast}) {
    return Movie(
      id: map['id'],
      title: map['title'],
      posterUrl: map['posterUrl'],
      director: map['director'],
      imdbRating: map['imdbRating'],
      badge: map['badge'],
      durationMinutes: map['durationMinutes'],
      releaseYear: map['releaseYear'],
      plot: map['plot'],
      genres: genres ?? const [],
      cast: cast ?? const [],
    );
  }
}