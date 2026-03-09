import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/log_model.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/services/access_control_service.dart';
import 'package:logbook_app_01/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  String _username = "User";
  late String _currentUserId;
  late String _currentUserRole;

  Future<void> init(String username) async {
    _username = username;
  }

  void setCurrentUser({required String userId, required String role}) {
    _currentUserId = userId;
    _currentUserRole = role;
  }

  Future<List<LogModel>> getLogs() async {
    final box = Hive.box<LogModel>('logbook_box');
    final localData = box.values.toList();
    if (localData.isNotEmpty) {
      logsNotifier.value = localData;
      filteredLogs.value = localData;
    }
    try {
      final data = await MongoService().getLogsByUser(_username);

      await LogHelper.writeLog(
        "INFO: Fetch logs success for $_username",
        source: "log_controller.dart",
        level: 3,
      );

      logsNotifier.value = data;
      filteredLogs.value = data;
      return data;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch logs failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      return [];
    }
  }

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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      desc: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      username: _username,
      authorId: _currentUserId,
      teamId: 'default_team',
    );

    final box = Hive.box<LogModel>('logbook_box');
    await box.put(newLog.id.toString(), newLog);

    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;

    try {
      await MongoService().insertLog(newLog);

      await LogHelper.writeLog(
        "SUCCESS: Log added & synced",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Data saved locally only - $e",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  Future<void> updateLog(
    LogModel log,
    String title,
    String desc,
    String category,
  ) async {
    final updatedLog = LogModel(
      id: log.id,
      title: title,
      desc: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      username: _username,
      authorId: log.authorId,
      teamId: log.teamId,
    );

    try {
      await MongoService().updateLog(updatedLog);

      await LogHelper.writeLog(
        "SUCCESS: Log updated",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> removeLog(LogModel log) async {
    final isOwner = log.authorId == _currentUserId;

    final canDelete = AccessControlService.canPerform(
      _currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );

    if (!canDelete) {
      await LogHelper.writeLog(
        "SECURITY: Delete denied for $_currentUserId",
        source: "log_controller.dart",
        level: 1,
      );

      throw Exception(
        "Akses ditolak: Anda tidak memiliki izin menghapus log ini.",
      );
    }

    if (log.id != null) {
      await MongoService().deleteLog(log.id!);

      logsNotifier.value = logsNotifier.value
          .where((l) => l.id != log.id)
          .toList();
      filteredLogs.value = logsNotifier.value;

      await LogHelper.writeLog(
        "SUCCESS: Log deleted",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }
}
