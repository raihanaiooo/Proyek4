class CounterController {
  //* ## Template Code Counter
  // int _counter = 0; //variable
  // int get value => _counter; //getter

  // void increment() => _counter++;

  // void decrement() {
  //   if (_counter > 0) {
  //     _counter--;
  //   }
  // }

  // void reset() => _counter = 0;

  //* ## TASK 1: Tambahkan fitur step increment dan step decrement menggunakan input dinamis
  // variabel
  int _step = 1;
  int _size = 1;
  final int _limit = 5;
  final List<String> _history = [];

  // Getter
  int get value => _step;
  List<String> get history => _history;

  // Methods
  void increment(String input) {
    final parse = int.tryParse(input);

    if (parse == null || parse <= 0) return;
    _size = parse;
    _step += _size;
    _addHistory("User menambah nilai sebesar $_size");
  }

  void decrement(String input) {
    final parse = int.tryParse(input);

    if (parse == null || parse <= 0) return;

    if (_step > 1) {
      _size = parse;
      _step -= _size;
      _addHistory("User mengurangi nilai sebesar $_size");
    }
  }

  void reset() {
    _step = 1;
    _addHistory("User reset ke $_step");
  }

  //* ## TASK 2: Tambahkan fitur history untuk menyimpan nilai-nilai step sebelumnya
  void _addHistory(String teks) {
    final timeStamp = DateTime.now();
    _history.insert(0, "$teks pada jam $timeStamp");

    if (_history.length > _limit) {
      _history.removeLast();
    }
  }
}
