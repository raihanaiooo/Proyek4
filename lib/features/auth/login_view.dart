import 'package:flutter/material.dart';
import 'package:logbook_app_01/features/auth/login_controller.dart';
import 'package:logbook_app_01/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  int _attempts = 0;
  bool _isLocked = false;
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
        ),
      );
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      _attempts = 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CounterView(username: user)),
      );
    } else {
      _attempts++;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Gagal! Username atau Password salah"),
        ),
      );

      if (_attempts >= 3) {
        _lockButton();
      }
    }
  }

  void _lockButton() {
    setState(() {
      _isLocked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terlalu banyak percobaan! Coba lagi nanti."),
      ),
    );

    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        _isLocked = false;
        _attempts = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLocked ? null : _handleLogin,
              child: Text(_isLocked ? "Tunggu 10 detik" : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
