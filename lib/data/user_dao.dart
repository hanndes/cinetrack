import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';
import 'database_helper.dart';

class UserDao {
  final dbHelper = DatabaseHelper.instance;

  // Kayıt ol
  Future<User> register(String name, String email, String password) async {
    final db = await dbHelper.database;

    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final user = User(
      name: name,
      email: email,
      passwordHash: hashedPassword,
    );

    final id = await db.insert('users', user.toMap()..remove('id'));

    return User(
      id: id,
      name: name,
      email: email,
      passwordHash: hashedPassword,
    );
  }

  // Email ile kullanıcı bul
  Future<User?> getUserByEmail(String email) async {
    final db = await dbHelper.database;

    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Giriş yap
  Future<User?> login(String email, String password) async {
    final user = await getUserByEmail(email);

    if (user == null) {
      return null; // Kullanıcı bulunamadı
    }

    final isPasswordCorrect = BCrypt.checkpw(password, user.passwordHash);

    if (isPasswordCorrect) {
      return user;
    } else {
      return null; // Şifre yanlış
    }
  }

  // Profil fotoğrafı yolunu güncelle
  Future<void> updateProfileImage(int userId, String imagePath) async {
    final db = await dbHelper.database;

    await db.update(
      'users',
      {'profileImageUrl': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}