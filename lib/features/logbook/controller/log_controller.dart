import 'package:flutter/material.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_model.dart';
import 'package:logbook_app_01/services/access_control_service.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  String _username = "User";
  late String _currentUserId;
  late String _currentUserRole;

  // String get _storageKey => "user_logs_data_$_username";

  Future<void> init(String username) async {
    _username = username;
    // await loadLogs();
    // await loadFromDisk();
  }

  void setCurrentUser({required String userId, required String role}) {
    _currentUserId = userId;
    _currentUserRole = role;
  }

  Future<List<LogModel>> getLogs() async {
    return await MongoService().getLogsByUser(_username);
  }

  // LogController() {
  //   loadFromDisk();
  // }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      title: title,
      desc: desc,
      date: DateTime.now().toString(),
      category: category,
      username: _username,
      authorId:
          _username, // Assuming username is unique and can serve as authorId
      teamId: 'default_team', // Placeholder teamId, adjust as needed
    );
    await MongoService().insertLog(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;
    // saveToDisk();
  }

  Future<void> updateLog(
    LogModel log,
    // int index,
    String title,
    String desc,
    String category,
  ) async {
    final updatedLog = LogModel(
      id: log.id,
      title: title,
      desc: desc,
      date: DateTime.now().toString(),
      category: category,
      username: _username,
      authorId: log.authorId,
      teamId: log.teamId,
    );

    await MongoService().updateLog(updatedLog);
    // final currentLogs = List<LogModel>.from(logsNotifier.value);
    // currentLogs[index] = LogModel(
    //   title: title,
    //   desc: desc,
    //   date: DateTime.now().toString(),
    //   category: category,
    // );
    // logsNotifier.value = currentLogs;
    // filteredLogs.value = logsNotifier.value;
    // saveToDisk();
  }

  Future<void> removeLog(LogModel log) async {
    final isOwner = log.authorId == _currentUserId;

    final canDelete = AccessControlService.canPerform(
      _currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );

    if (!canDelete) {
      throw Exception(
        "Akses ditolak: Anda tidak memiliki izin menghapus log ini.",
      );
    }
    if (log.id != null) {
      await MongoService().deleteLog(log.id!);
    }
    // final currentLogs = List<LogModel>.from(logsNotifier.value);
    // currentLogs.removeAt(index);
    // logsNotifier.value = currentLogs;
    // filteredLogs.value = logsNotifier.value;
    // saveToDisk();
  }

  // Future<void> saveToDisk() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String encodedData = jsonEncode(
  //     logsNotifier.value.map((e) => e.toMap()).toList(),
  //   );
  //   await prefs.setString(_storageKey, encodedData);
  // }

  // Future<void> loadFromDisk() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String? rawJson = prefs.getString(_storageKey);

  //   if (rawJson != null) {
  //     logsNotifier.value = _mapJsonToLogs(rawJson);
  //   }

  //   filteredLogs.value = logsNotifier.value;
  // }

  // List<LogModel> _mapJsonToLogs(String rawJson) {
  //   final Iterable decoded = jsonDecode(rawJson);
  //   return decoded.map((e) => LogModel.fromMap(e)).toList();
  // }
}
