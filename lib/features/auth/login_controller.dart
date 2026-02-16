class LoginController {
  // Database hardcoded untuk validasi login
  final String _validUsername = "admin";
  final String _validPassword = "123";

  // Fungi pengecekan (logic only)
  bool login(String username, String password) {
    if (username == _validUsername && password == _validPassword) {
      return true;
    }
    return false;
  }
}
