import 'package:flutter/foundation.dart';
import '../models/user.dart';

// ChangeNotifier: bu sınıfın "dinlenebilir" olmasını sağlıyor.
// notifyListeners() çağrıldığında, bu nesneyi Provider ile dinleyen
// TÜM widget'lar otomatik olarak yeniden çiziliyor.
//
// Java/Spring analojisi: notifyListeners() bir event publish etmek gibi,
// dinleyen widget'lar ise @EventListener ile o event'i dinleyen yerler gibi.
//
// Singleton yapısı (instance) korunuyor, yani mevcut kodundaki
// CurrentUser.instance.user gibi kullanımlar hâlâ çalışıyor. Tek fark:
// artık setUser/clear çağrıldığında dinleyen widget'lar haberdar oluyor.
class CurrentUser extends ChangeNotifier {
  static final CurrentUser instance = CurrentUser._init();
  CurrentUser._init();

  User? user;

  void setUser(User user) {
    this.user = user;
    notifyListeners();
  }

  void clear() {
    user = null;
    notifyListeners();
  }
}