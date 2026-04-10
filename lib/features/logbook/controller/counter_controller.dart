import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  String _username = "User";

  // Fungsi menyimpan angka terakhir
  Future<void> saveLastValue(int value, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_counter_$username', value);
  }

  // Fungsi membaca data / load
  Future<int> loadLastValue(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_counter_$username') ?? 0;
  }

  //* ## TASK 1: Tambahkan fitur step increment dan step decrement menggunakan input dinamis
  // variabel
  int _step = 1;
  int _size = 1;
  final int _limit = 5;
  final List<String> _history = [];
  String get _historyKey => "counter_value_$_username";

  // Getter
  int get value => _step;
  List<String> get history => _history;

  // Methods
  Future<void> init(String username) async {
    _username = username;
    _step = await loadLastValue(username);
    await _loadHistory();
  }

  Future<void> increment(String input) async {
    final parse = int.tryParse(input);

    if (parse == null || parse <= 0) return;
    _size = parse;
    _step += _size;

    await saveLastValue(_step, _username);
    await _addHistory("User menambah nilai sebesar $_size");
  }

  Future<void> decrement(String input) async {
    final parse = int.tryParse(input);

    if (parse == null || parse <= 0) return;

    if (_step > 1) {
      _size = parse;
      _step = (_step - _size).clamp(0, double.maxFinite.toInt());

      await saveLastValue(_step, _username);
      await _addHistory("User mengurangi nilai sebesar $_size");
    }
  }

  Future<void> reset() async {
    _step = 1;

    await saveLastValue(_step, _username);
    await _addHistory("User reset ke $_step");
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_historyKey);

    _history.clear();
    if (data != null) {
      _history.addAll(data);
    }
  }

  //* ## TASK 2: Tambahkan fitur history untuk menyimpan nilai-nilai step sebelumnya
  Future<void> _addHistory(String teks, {String user = "User"}) async {
    final timeStamp = DateTime.now();
    _history.insert(0, "$user: $teks pada jam $timeStamp");

    if (_history.length > _limit) {
      _history.removeLast();
    }

    await _saveHistory();
  }

  String getGreeting({required String username, required DateTime login}) {
    final hour = login.hour;
    String greeting;

    if (hour >= 6 && hour <= 11) {
      greeting = "Selamat Pagi";
    } else if (hour >= 12 && hour <= 15) {
      greeting = "Selamat Siang";
    } else if (hour >= 16 && hour <= 18) {
      greeting = "Selamat Sore";
    } else {
      greeting = "Selamat Malam";
    }

    return "$greeting, $username!";
  }
}
