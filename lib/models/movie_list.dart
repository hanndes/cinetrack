class MovieList {
  final int? id;
  final int userId;
  final String name;
  final String? createdDate;

  MovieList({
    this.id,
    required this.userId,
    required this.name,
    this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'createdDate': createdDate,
    };
  }

  factory MovieList.fromMap(Map<String, dynamic> map) {
    return MovieList(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      createdDate: map['createdDate'],
    );
  }
}