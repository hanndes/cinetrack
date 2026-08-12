import 'package:flutter_test/flutter_test.dart';
import 'package:cinetrack_process/models/user.dart';

void main() {
  group('User modeli', () {
    test('toMap ve fromMap round trip doğru çalışıyor', () {
      final user = User(
        id: 1,
        name: 'Hande',
        email: 'hande@example.com',
        passwordHash: r'$2b$10$hashvalue',
        profileImageUrl: null,
      );

      final map = user.toMap();
      final roundTripped = User.fromMap(map);

      expect(roundTripped.id, user.id);
      expect(roundTripped.name, user.name);
      expect(roundTripped.email, user.email);
      expect(roundTripped.passwordHash, user.passwordHash);
    });

    test('copyWith sadece belirtilen alanları değiştiriyor', () {
      final user = User(
        id: 1,
        name: 'Hande',
        email: 'hande@example.com',
        passwordHash: 'hash1',
      );

      final updated = user.copyWith(name: 'Hande Y.');

      expect(updated.name, 'Hande Y.');
      expect(updated.email, user.email); // değişmedi
      expect(updated.id, user.id); // değişmedi
    });

    test('copyWith hiçbir parametre verilmezse aynı değerleri korur', () {
      final user = User(
        id: 5,
        name: 'Test User',
        email: 'test@example.com',
        passwordHash: 'hash',
        profileImageUrl: 'https://example.com/avatar.jpg',
      );

      final copy = user.copyWith();

      expect(copy.id, user.id);
      expect(copy.name, user.name);
      expect(copy.email, user.email);
      expect(copy.profileImageUrl, user.profileImageUrl);
    });
  });
}