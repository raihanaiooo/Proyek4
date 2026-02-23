import 'package:shared_preferences/shared_preferences.dart';

class LoginController {
  // Database hardcoded untuk validasi login
  Map<String, String> _users = {"admin": "123", "sasa": "sasa123"};

  // Fungi pengecekan (logic only)
  bool login(String username, String password) {
    return _users[username] == password;
  }

  Future<void> saveCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("current_user", username);
  }
}
