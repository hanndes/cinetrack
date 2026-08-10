import '../models/user.dart';

class CurrentUser {
  static final CurrentUser instance = CurrentUser._init();
  CurrentUser._init();

  User? user;

  void setUser(User user) {
    this.user = user;
  }

  void clear() {
    user = null;
  }
}