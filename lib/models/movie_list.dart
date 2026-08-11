class MovieList {
  final int? id;
  final int userId;
  final String name;
  final String? emoji;
  final String? color; // hex string, örn: "#7C4DFF"
  final String? description;
  final String? createdDate;

  MovieList({
    this.id,
    required this.userId,
    required this.name,
    this.emoji,
    this.color,
    this.description,
    this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'emoji': emoji,
      'color': color,
      'description': description,
      'createdDate': createdDate,
    };
  }

  factory MovieList.fromMap(Map<String, dynamic> map) {
    return MovieList(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      emoji: map['emoji'],
      color: map['color'],
      description: map['description'],
      createdDate: map['createdDate'],
    );
  }
}