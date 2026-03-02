import 'package:flutter/material.dart';
import '../models/log_model.dart';
import '../controller/log_controller.dart';
import '../widgets/log_item_widget.dart';
import '../widgets/add_log_dialog.dart';
import '../widgets/edit_log_dialog.dart';
import '../widgets/logout_dialog.dart';
import 'package:logbook_app_01/helpers/log_helper.dart';
import 'package:logbook_app_01/services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  bool _isLoading = false;
  final LogController _controller = LogController();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.username);

    Future.microtask(() => _initDatabase());
  }

  Future<void> _initDatabase() async {
    setState(() => _isLoading = true);

    try {
      await LogHelper.writeLog(
        "UI: Memulai inisialisasi database...",
        source: "log_view.dart",
      );

      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      await _controller.loadFromDisk();

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat ke Notifier.",
        source: "log_view.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Error - $e",
        source: "log_view.dart",
        level: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masalah: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke MongoDB Atlas"),
                ],
              ),
            );
          }
          if (currentLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Belum ada catatan di Cloud."),
                  ElevatedButton(
                    onPressed: _showAddDialog,
                    child: const Text("Buat Catatan Pertama"),
                  ),
                ],
              ),
            );
          }
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
                child: ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Dismissible(
                      key: Key(log.date),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        _controller.removeLog(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Catatan dihapus')),
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
