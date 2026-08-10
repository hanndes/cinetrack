import '../data/user_dao.dart';
import '../models/user.dart';

class AuthService {
  final UserDao _userDao = UserDao();

  Future<String?> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Lütfen tüm alanları doldurun';
    }

    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    final existingUser = await _userDao.getUserByEmail(email);
    if (existingUser != null) {
      return 'Bu email zaten kullanılıyor';
    }

    try {
      await _userDao.register(name, email, password);
      return null; // null = hata yok, başarılı
    } catch (e) {
      return 'Kayıt sırasında bir hata oluştu';
    }
  }

  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return null;
    }
    return await _userDao.login(email, password);
  }
}