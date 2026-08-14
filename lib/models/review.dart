class Review {
  final int? id;
  final int userId;
  final int movieId;
  final double rating;
  final String? reviewText;
  final String? reviewDate;

  // Join ile geldiğinde kullanıcı adını da taşımak için (opsiyonel)
  final String? userName;

  Review({
    this.id,
    required this.userId,
    required this.movieId,
    required this.rating,
    this.reviewText,
    this.reviewDate,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'movie_id': movieId,
      'rating': rating,
      'review_text': reviewText,
      'review_date': reviewDate,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      userId: map['user_id'],
      movieId: map['movie_id'],
      rating: (map['rating'] as num).toDouble(),
      reviewText: map['review_text'],
      reviewDate: map['review_date'],
      userName: map['userName'],
    );
  }
}