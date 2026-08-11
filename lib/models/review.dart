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
      'userId': userId,
      'movieId': movieId,
      'rating': rating,
      'reviewText': reviewText,
      'reviewDate': reviewDate,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      userId: map['userId'],
      movieId: map['movieId'],
      rating: (map['rating'] as num).toDouble(),
      reviewText: map['reviewText'],
      reviewDate: map['reviewDate'],
      userName: map['userName'],
    );
  }
}