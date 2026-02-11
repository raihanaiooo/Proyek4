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

  //* ## TASK 1: Tambahkan fitur step increment dan step decrement sebesar 5
  // variabel
  int _step = 1;
  final int _size = 5;
  final List<String> _history = [];

  // Getter
  int get value => _step;
  List<String> get history => _history;

  // Methods
  void increment() {
    _step += _size;
    _addHistory("User menambah nilai sebesar $_size");
  }

  void decrement() {
    if (_step > 1) {
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

    if (_history.length > _size) {
      _history.removeLast();
    }
  }
}
