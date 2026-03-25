import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/log_model.dart';
import '../controller/log_controller.dart';
import '../widgets/log_item_widget.dart';
import '../widgets/logout_dialog.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/features/logbook/views/log_editor_page.dart';

class LogView extends StatefulWidget {
  final String username;
  final String currentUserId;
  final String currentUserRole;
  final String currentTeamId;

  const LogView({
    super.key,
    required this.username,
    required this.currentUserId,
    required this.currentUserRole,
    required this.currentTeamId,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  bool _isDeleting = false;
  bool _isOffline = false;

  late Future<List<LogModel>> _logsFuture;
  final LogController _controller = LogController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _controller.init(widget.username);
    _controller.setCurrentUser(
      userId: widget.currentUserId,
      role: widget.currentUserRole,
      teamId: widget.currentTeamId,
    );
    _logsFuture = _fetchLogs();
  }

  Future<bool> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    final offline = result == ConnectivityResult.none;
    if (mounted) setState(() => _isOffline = offline);
    return !offline;
  }

  Future<List<LogModel>> _fetchLogs() async {
    await _checkConnection();
    if (!_isOffline) {
      try {
        await MongoService().connect().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception("Timeout"),
        );
      } catch (_) {
        if (mounted) setState(() => _isOffline = true);
      }
    }
    return await _controller.getLogs();
  }

  void _refreshLogs() {
    _logsFuture = _fetchLogs();
    if (mounted) setState(() {});
  }

  Future<void> _openAddPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          controller: _controller,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _refreshLogs();
  }

  Future<void> _openEditPage(LogModel log) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
    _refreshLogs();
  }

  Future<void> _deleteLog(LogModel log) async {
    setState(() => _isDeleting = true);
    try {
      await _controller.removeLog(log);
      _refreshLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inHours < 24) return timeago.format(date, locale: 'id');
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Mechanical":
        return Colors.green.shade100;
      case "Electronic":
        return Colors.blue.shade100;
      case "Software":
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 500,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.note_alt_outlined,
                    size: 72,
                    color: Colors.green.shade300,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Belum ada aktivitas hari ini!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mulai catat kemajuan proyek Anda\ndengan menekan tombol + di bawah.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _openAddPage,
                  icon: const Icon(Icons.add),
                  label: const Text("Buat Catatan Pertama"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logbook'),
        actions: [
          ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (_, logs, __) {
              final hasUnsynced = _isOffline || logs.any((l) => !l.isSynced);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: hasUnsynced
                      ? 'Ada data belum tersync'
                      : 'Semua data tersync',
                  child: Icon(
                    hasUnsynced ? Icons.cloud_off : Icons.cloud_done,
                    color: hasUnsynced ? Colors.orange : Colors.green,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LogoutDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner offline
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Text(
                "⚠️ Offline — menampilkan data lokal",
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),

          if (_isDeleting) const LinearProgressIndicator(),

          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allLogs = snapshot.data ?? [];

                // Task 5: filter visibilitas
                final visibleLogs = allLogs.where((log) {
                  return log.authorId == widget.currentUserId ||
                      log.isPublic == true;
                }).toList();

                if (visibleLogs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _logsFuture = _fetchLogs();
                      setState(() {});
                      await _logsFuture;
                    },
                    child: _buildEmptyState(),
                  );
                }

                return Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        onChanged: _controller.searchLog,
                        decoration: const InputDecoration(
                          hintText: 'Cari judul atau isi catatan...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          _logsFuture = _fetchLogs();
                          setState(() {});
                          await _logsFuture;
                        },
                        child: ValueListenableBuilder<List<LogModel>>(
                          valueListenable: _controller.filteredLogs,
                          builder: (_, filteredAll, __) {
                            final filtered = filteredAll.where((log) {
                              return log.authorId == widget.currentUserId ||
                                  log.isPublic == true;
                            }).toList();

                            if (filtered.isEmpty) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      "Tidak ada catatan yang cocok.",
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final log = filtered[index];
                                final isOwner =
                                    log.authorId == widget.currentUserId;

                                final item = LogItemWidget(
                                  log: log,
                                  categoryColor: _getCategoryColor(
                                    log.category,
                                  ),
                                  formattedDate: _formatDate(
                                    DateTime.parse(log.date),
                                  ),
                                  onEdit: isOwner
                                      ? () => _openEditPage(log)
                                      : null,
                                );

                                if (!isOwner) return item;

                                return Dismissible(
                                  key: ValueKey(log.id ?? log.date),
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
                                  confirmDismiss: (_) async => true,
                                  onDismissed: (_) async {
                                    _controller.logsNotifier.value = _controller
                                        .logsNotifier
                                        .value
                                        .where((l) => l.id != log.id)
                                        .toList();
                                    _controller.filteredLogs.value =
                                        _controller.logsNotifier.value;
                                    await _deleteLog(log);
                                  },
                                  child: item,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}
