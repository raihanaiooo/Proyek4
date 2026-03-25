import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  final String username;
  final String password;
  final String role;
  final String userId;
  final String teamId;

  const UserData({
    required this.username,
    required this.password,
    required this.role,
    required this.userId,
    required this.teamId,
  });
}

class LoginController {
  static const List<UserData> _users = [
    UserData(
      username: 'ketua',
      password: 'ketua123',
      role: 'Ketua',
      userId: 'user_001',
      teamId: 'team_alpha',
    ),
    UserData(
      username: 'anggota',
      password: 'anggota123',
      role: 'Anggota',
      userId: 'user_002',
      teamId: 'team_alpha',
    ),
    UserData(
      username: 'asisten',
      password: 'asisten123',
      role: 'Asisten',
      userId: 'user_003',
      teamId: 'team_alpha',
    ),
  ];

  UserData? login(String username, String password) {
    try {
      return _users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  // Simpan sesi ke SharedPreferences
  Future<void> saveCurrentUser(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', user.username);
    await prefs.setString('current_user_id', user.userId);
    await prefs.setString('current_user_role', user.role);
    await prefs.setString('current_team_id', user.teamId);
  }

  // Ambil sesi yang tersimpan
  Future<Map<String, String?>> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('current_user'),
      'userId': prefs.getString('current_user_id'),
      'role': prefs.getString('current_user_role'),
      'teamId': prefs.getString('current_team_id'),
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_role');
    await prefs.remove('current_team_id');
  }
}
