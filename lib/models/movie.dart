class Movie {
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
}