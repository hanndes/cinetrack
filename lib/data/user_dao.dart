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

  // İsim ve email güncelle
  Future<void> updateProfile(int userId, String name, String email) async {
    final db = await dbHelper.database;

    await db.update(
      'users',
      {'name': name, 'email': email},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Şifre değiştir (mevcut şifreyi doğrulayarak)
  // Döner: true -> başarılı, false -> mevcut şifre yanlış
  Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    final db = await dbHelper.database;

    final maps = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (maps.isEmpty) return false;

    final user = User.fromMap(maps.first);
    final isCurrentCorrect = BCrypt.checkpw(currentPassword, user.passwordHash);
    if (!isCurrentCorrect) return false;

    final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await db.update(
      'users',
      {'passwordHash': newHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return true;
  }

  // Hesabı sil (ilişkili tüm verilerle birlikte)
  Future<void> deleteAccount(int userId) async {
    final db = await dbHelper.database;
    await db.delete('reviews', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('watchlist', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('watched', where: 'userId = ?', whereArgs: [userId]);
    await db.delete('favorites', where: 'userId = ?', whereArgs: [userId]);

    // Kullanıcının listelerindeki list_items'ları da temizle
    final lists = await db.query('lists', where: 'userId = ?', whereArgs: [userId]);
    for (final list in lists) {
      await db.delete('list_items', where: 'listId = ?', whereArgs: [list['id']]);
    }
    await db.delete('lists', where: 'userId = ?', whereArgs: [userId]);

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }
}