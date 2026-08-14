import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';

class UserDao {
  final supabase = Supabase.instance.client;

  // Kayıt ol
  Future<User> register(String name, String email, String password) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    final response = await supabase.from('users').insert({
      'name': name,
      'email': email,
      'password_hash': hashedPassword,
    }).select().single();

    return User.fromMap(response);
  }

  // Email ile kullanıcı bul
  Future<User?> getUserByEmail(String email) async {
    final maps = await supabase.from('users').select().eq('email', email);
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
    await supabase
        .from('users')
        .update({'profile_image_url': imagePath})
        .eq('id', userId);
  }

  // İsim ve email güncelle
  Future<void> updateProfile(int userId, String name, String email) async {
    await supabase
        .from('users')
        .update({'name': name, 'email': email})
        .eq('id', userId);
  }

  // Şifre değiştir (mevcut şifreyi doğrulayarak)
  // Döner: true -> başarılı, false -> mevcut şifre yanlış
  Future<bool> changePassword(
      int userId, String currentPassword, String newPassword) async {
    final maps = await supabase.from('users').select().eq('id', userId);
    if (maps.isEmpty) return false;

    final user = User.fromMap(maps.first);
    final isCurrentCorrect = BCrypt.checkpw(currentPassword, user.passwordHash);
    if (!isCurrentCorrect) return false;

    final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await supabase
        .from('users')
        .update({'password_hash': newHash})
        .eq('id', userId);
    return true;
  }

  // Hesabı sil (ilişkili tüm verilerle birlikte)
  // Not: tablolarda "on delete cascade" tanımlı olduğu için users'tan
  // silmek yeterli, ilişkili favorites/watchlist/watched/reviews/lists/
  // list_items kayıtları otomatik silinir.
  Future<void> deleteAccount(int userId) async {
    await supabase.from('users').delete().eq('id', userId);
  }
}