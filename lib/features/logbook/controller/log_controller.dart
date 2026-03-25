import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/log_model.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/services/access_control_service.dart';
import 'package:logbook_app_01/features/logbook/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  String _username = "User";
  late String _currentUserId;
  late String _currentUserRole;
  late String _teamId;

  Future<void> init(String username) async {
    _username = username;
  }

  void setCurrentUser({
    required String userId,
    required String role,
    required String teamId,
  }) {
    _currentUserId = userId;
    _currentUserRole = role;
    _teamId = teamId;
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<List<LogModel>> getLogs() async {
    final box = Hive.box<LogModel>('logbook_box');
    final localData = box.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;

    if (await _isOnline()) {
      try {
        // final remoteData = await MongoService().getLogsByUser(_username);
        final remoteData = await MongoService().getLogsByTeam(_teamId);
        for (final log in remoteData) {
          if (log.id != null) {
            await box.put(log.id!, log.copyWith(isSynced: true));
          }
        }
        final mergedData = box.values.toList();
        logsNotifier.value = mergedData;
        filteredLogs.value = mergedData;
        await _syncPendingLogs();
        return mergedData;
      } catch (e) {
        await LogHelper.writeLog(
          "WARN: Remote fetch failed, using local - $e",
          source: "log_controller.dart",
          level: 2,
        );
      }
    }
    return box.values.toList();
  }

  Future<void> _syncPendingLogs() async {
    final box = Hive.box<LogModel>('logbook_box');
    final unsyncedLogs = box.values.where((log) => !log.isSynced).toList();

    for (final log in unsyncedLogs) {
      if (log.id == null || log.id!.length != 24) {
        await box.delete(log.id);
        await LogHelper.writeLog(
          "CLEANUP: Hapus log dengan ID tidak valid: ${log.id}",
          source: "log_controller.dart",
          level: 2,
        );
        continue;
      }

      try {
        await MongoService().insertLog(log);
        await box.put(log.id!, log.copyWith(isSynced: true));

        await LogHelper.writeLog(
          "SYNC: Log ${log.id} berhasil dikirim ke MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC ERROR: Gagal sync log ${log.id} - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }

    logsNotifier.value = box.values.toList();
    filteredLogs.value = logsNotifier.value;
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.desc.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String category, {
    bool isPublic = false,
  }) async {
    final newLog = LogModel(
      id: ObjectId().toHexString(),
      title: title,
      desc: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      username: _username,
      authorId: _currentUserId,
      teamId: _teamId,
      isSynced: false,
      isPublic: isPublic,
    );

    final box = Hive.box<LogModel>('logbook_box');
    await box.put(newLog.id!, newLog);

    logsNotifier.value = [...logsNotifier.value, newLog];
    filteredLogs.value = logsNotifier.value;

    if (await _isOnline()) {
      try {
        await MongoService().insertLog(newLog);
        await box.put(newLog.id!, newLog.copyWith(isSynced: true));

        logsNotifier.value = box.values.toList();
        filteredLogs.value = logsNotifier.value;

        await LogHelper.writeLog(
          "SUCCESS: Log added & synced to MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "OFFLINE: Log saved locally, will sync later - $e",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } else {
      await LogHelper.writeLog(
        "OFFLINE: Log saved locally only (no connection)",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  Future<void> updateLog(
    LogModel log,
    String title,
    String desc,
    String category, {
    bool? isPublic,
  }) async {
    final updatedLog = LogModel(
      id: log.id,
      title: title,
      desc: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      username: _username,
      authorId: log.authorId,
      teamId: log.teamId,
      isSynced: false,
      isPublic: isPublic ?? log.isPublic,
    );

    final box = Hive.box<LogModel>('logbook_box');
    await box.put(updatedLog.id!, updatedLog);

    logsNotifier.value = box.values.toList();
    filteredLogs.value = logsNotifier.value;

    if (await _isOnline()) {
      try {
        await MongoService().updateLog(updatedLog);
        await box.put(updatedLog.id!, updatedLog.copyWith(isSynced: true));

        logsNotifier.value = box.values.toList();
        filteredLogs.value = logsNotifier.value;

        await LogHelper.writeLog(
          "SUCCESS: Log updated & synced",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "OFFLINE: Update saved locally, will sync later - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
  }

  // Task 5: Hanya owner yang bisa hapus, role tidak relevan
  Future<void> removeLog(LogModel log) async {
    final isOwner = log.authorId == _currentUserId;

    if (!isOwner) {
      await LogHelper.writeLog(
        "SECURITY: Delete denied for $_currentUserId (bukan pemilik)",
        source: "log_controller.dart",
        level: 1,
      );
      throw Exception(
        "Akses ditolak: Hanya pemilik catatan yang dapat menghapus.",
      );
    }

    if (log.id == null) return;

    final box = Hive.box<LogModel>('logbook_box');
    await box.delete(log.id);

    logsNotifier.value = logsNotifier.value
        .where((l) => l.id != log.id)
        .toList();
    filteredLogs.value = logsNotifier.value;

    if (await _isOnline()) {
      if (log.id!.length != 24) return;

      try {
        await MongoService().deleteLog(log.id!);

        await LogHelper.writeLog(
          "SUCCESS: Log deleted from local & MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "OFFLINE: Deleted locally, MongoDB delete pending - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
  }
}
