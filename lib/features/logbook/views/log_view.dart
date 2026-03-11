import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/log_model.dart';
import '../controller/log_controller.dart';
import '../widgets/log_item_widget.dart';
// import '../widgets/add_log_dialog.dart';
// import '../widgets/edit_log_dialog.dart';
import '../widgets/logout_dialog.dart';
import 'package:logbook_app_01/helpers/log_helper.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/services/access_control_service.dart';
import 'package:logbook_app_01/features/logbook/log_editor_page.dart';

class LogView extends StatefulWidget {
  final String username;
  final String currentUserId;
  final String currentUserRole;
  const LogView({
    super.key,
    required this.username,
    required this.currentUserId,
    required this.currentUserRole,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  bool _isDeleting = false;
  bool _isLoading = false;
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
    );

    _logsFuture = _fetchLogs();
  }

  // CONNECTION GUARD
  Future<bool> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      setState(() => _isOffline = true);
      return false;
    }

    setState(() => _isOffline = false);
    return true;
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

  // Future<void> _initDatabase() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     await MongoService().connect().timeout(
  //       const Duration(seconds: 15),
  //       onTimeout: () => throw Exception("Koneksi Cloud Timeout."),
  //     );
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Offline Mode Warning"),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _openAddPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LogEditorPage(controller: _controller)),
    );
    _refreshLogs();
  }

  Future<void> _openEditPage(LogModel log) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogEditorPage(log: log, controller: _controller),
      ),
    );
    _refreshLogs();
  }

  // Future<void> _showAddDialog() async {
  //   await showDialog(
  //     context: context,
  //     builder: (context) => AddLogDialog(controller: _controller),
  //   );
  //   _refreshLogs();
  // }

  // Future<void> _showEditDialog(int index, LogModel log) async {
  //   await showDialog(
  //     context: context,
  //     builder: (context) =>
  //         EditLogDialog(controller: _controller, log: log, index: index),
  //   );
  //   _refreshLogs();
  // }

  Future<void> _deleteLog(LogModel log) async {
    setState(() => _isDeleting = true);

    try {
      await _controller.removeLog(log);

      _refreshLogs();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return timeago.format(date, locale: 'id');
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }
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
      body: Column(
        children: [
          // Banner offline — tidak memblok konten
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

          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final currentLogs = snapshot.data ?? [];

                if (currentLogs.isEmpty) {
                  return const Center(child: Text("Belum ada catatan."));
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
                      child: Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: () async => _refreshLogs(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: currentLogs.length,
                              itemBuilder: (context, index) {
                                final log = currentLogs[index];

                                final canDelete =
                                    AccessControlService.canPerform(
                                      widget.currentUserRole,
                                      AccessControlService.actionDelete,
                                      isOwner:
                                          log.authorId == widget.currentUserId,
                                    );

                                final canEdit = AccessControlService.canPerform(
                                  widget.currentUserRole,
                                  AccessControlService.actionUpdate,
                                  isOwner: log.authorId == widget.currentUserId,
                                );

                                return canDelete
                                    ? Dismissible(
                                        key: ValueKey(
                                          log.id?.toString() ??
                                              log.date.toString(),
                                        ),
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
                                          final logToDelete = log;
                                          _controller.logsNotifier.value =
                                              _controller.logsNotifier.value
                                                  .where(
                                                    (l) =>
                                                        l.id != logToDelete.id,
                                                  )
                                                  .toList();
                                          await _deleteLog(logToDelete);
                                        },
                                        child: Material(
                                          color: Colors.transparent,
                                          child: LogItemWidget(
                                            log: log,
                                            formattedDate: _formatDate(
                                              DateTime.parse(log.date),
                                            ),
                                            onEdit: canEdit
                                                ? () => _openEditPage(log)
                                                : null,
                                          ),
                                        ),
                                      )
                                    : LogItemWidget(
                                        log: log,
                                        formattedDate: _formatDate(
                                          DateTime.parse(log.date),
                                        ),
                                        onEdit: canEdit
                                            ? () => _openEditPage(log)
                                            : null,
                                      );
                              },
                            ),
                          ),
                          if (_isDeleting)
                            Container(
                              color: Colors.black38,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
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
