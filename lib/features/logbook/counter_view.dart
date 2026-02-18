import 'package:flutter/material.dart';
import 'package:logbook_app_01/features/onboarding/onboarding_view.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  final String username;
  final DateTime login;

  const CounterView({super.key, required this.username, required this.login});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.username).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // title: Text("Logbook: ${widget.username}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi Logout"),
                    content: const Text(
                      "Apakah Anda yakin? Data yang belum disimpan mungkin akan hilang.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OnboardingView(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Ya, Keluar",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _controller.getGreeting(
                username: widget.username,
                login: widget.login,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            const Text("Total Hitungan Step: "),
            Text('${_controller.value}', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                focusColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'Masukan angka',
                hintStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const Text(
              "History Step:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _controller.history.length,
                itemBuilder: (context, index) {
                  String entry = _controller.history[index];

                  Color text = Colors.black;
                  if (entry.contains("menambah")) {
                    text = Colors.green;
                  } else if (entry.contains("mengurangi")) {
                    text = Colors.red;
                  } else if (entry.contains("reset")) {
                    text = Colors.blue;
                  }
                  return Card(
                    child: ListTile(
                      title: Text(entry, style: TextStyle(color: text)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: () async => await _controller
                  .decrement(_textController.text)
                  .then((_) => setState(() {})),
              child: const Icon(Icons.remove),
            ),
            FloatingActionButton(
              onPressed: () => {
                showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Reset Counter"),
                      content: const Text(
                        "Apakah Anda yakin ingin mereset counter?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _controller.reset();
                            setState(() {});
                            final snackBar = SnackBar(
                              content: const Text("Counter berhasil di Reset!"),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          },
                          child: const Text("Reset"),
                        ),
                      ],
                    );
                  },
                ),
              },
              child: const Text("Reset"),
            ),
            FloatingActionButton(
              onPressed: () async => await _controller
                  .increment(_textController.text)
                  .then((_) => setState(() {})),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
