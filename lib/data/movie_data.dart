import '../models/movie.dart';

List<Movie> dummyMovies = [
  Movie(
    title: "Inception",
    director: "Christopher Nolan",
    imdbRating: 8.8,
    posterUrl: "https://picsum.photos/200/300?1",
    badge: "Trending #1",
    durationMinutes: 148,
    releaseYear: 2010,
    cast: ["Leonardo DiCaprio", "Ellen Page", "Tom Hardy"],
    genres: ["Sci-Fi", "Thriller"],
  ),
  Movie(
    title: "Interstellar",
    director: "Christopher Nolan",
    imdbRating: 8.6,
    posterUrl: "https://picsum.photos/200/300?2",
    durationMinutes: 169,
    releaseYear: 2014,
    cast: ["Matthew McConaughey", "Anne Hathaway"],
    genres: ["Sci-Fi", "Adventure"],
  ),
  Movie(
    title: "The Godfather",
    director: "Francis Ford Coppola",
    imdbRating: 9.2,
    posterUrl: "https://picsum.photos/200/300?3",
    durationMinutes: 175,
    releaseYear: 1972,
    cast: ["Marlon Brando", "Al Pacino"],
    genres: ["Crime", "Drama"],
  ),
];