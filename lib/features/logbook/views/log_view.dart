import 'package:flutter/material.dart';
import '../models/log_model.dart';
import '../controller/log_controller.dart';
import '../widgets/log_item_widget.dart';
import '../widgets/add_log_dialog.dart';
import '../widgets/edit_log_dialog.dart';
import '../widgets/logout_dialog.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.username);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddLogDialog(controller: _controller),
    );
  }

  void _showEditDialog(int index, LogModel log) {
    showDialog(
      context: context,
      builder: (context) =>
          EditLogDialog(controller: _controller, log: log, index: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const LogoutDialog(),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.filteredLogs,
        builder: (context, currentLogs, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) => _controller.searchLog(value),
                  decoration: const InputDecoration(
                    hintText: 'Cari catatan...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: currentLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/empty.gif', height: 120),
                            const SizedBox(height: 12),
                            const Text('Belum ada catatan.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) {
                          final log = currentLogs[index];
                          return Dismissible(
                            key: Key(log.date),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) {
                              _controller.removeLog(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Catatan dihapus'),
                                ),
                              );
                            },
                            child: LogItemWidget(
                              log: log,
                              onEdit: () => _showEditDialog(index, log),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
