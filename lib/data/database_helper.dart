import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cinetrack.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        profileImageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE movies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        posterUrl TEXT NOT NULL,
        director TEXT,
        imdbRating REAL,
        badge TEXT,
        durationMinutes INTEGER,
        releaseYear INTEGER,
        plot TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE genres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE movie_genres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        genreId INTEGER NOT NULL,
        FOREIGN KEY (movieId) REFERENCES movies (id),
        FOREIGN KEY (genreId) REFERENCES genres (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE artists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photoUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE movie_cast (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movieId INTEGER NOT NULL,
        artistId INTEGER NOT NULL,
        role TEXT,
        FOREIGN KEY (movieId) REFERENCES movies (id),
        FOREIGN KEY (artistId) REFERENCES artists (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (movieId) REFERENCES movies (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (movieId) REFERENCES movies (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE watched (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        watchedDate TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (movieId) REFERENCES movies (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        rating REAL NOT NULL,
        reviewText TEXT,
        reviewDate TEXT,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (movieId) REFERENCES movies (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        emoji TEXT,
        color TEXT,
        description TEXT,
        createdDate TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE list_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        listId INTEGER NOT NULL,
        movieId INTEGER NOT NULL,
        FOREIGN KEY (listId) REFERENCES lists (id),
        FOREIGN KEY (movieId) REFERENCES movies (id)
      )
    ''');
  }
}