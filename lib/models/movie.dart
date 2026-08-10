class Movie {
  final int? id;
  final String title;
  final String director;
  final double imdbRating;
  final String posterUrl;
  final String? badge;
  final int durationMinutes;
  final int releaseYear;
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
    required this.cast,
    required this.genres,
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
      'genres': genres.join(','),
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      title: map['title'],
      posterUrl: map['posterUrl'],
      director: map['director'],
      imdbRating: map['imdbRating'],
      badge: map['badge'],
      durationMinutes: map['durationMinutes'],
      releaseYear: map['releaseYear'],
      genres: (map['genres'] as String).split(','),
      cast: const [],
    );
  }
}