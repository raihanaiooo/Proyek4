class LoginController {
  // Database hardcoded untuk validasi login

  Map<String, String> _users = {"admin": "123", "sasa": "sasa123"};
  // final String _validUsername = "admin";
  // final String _validPassword = "123";

  // Fungi pengecekan (logic only)
  bool login(String username, String password) {
    return _users[username] == password;
  }
}
