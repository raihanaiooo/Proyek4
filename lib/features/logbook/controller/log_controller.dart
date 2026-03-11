import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/log_model.dart';
import 'package:logbook_app_01/services/mongo_service.dart';
import 'package:logbook_app_01/services/access_control_service.dart';
import 'package:logbook_app_01/helpers/log_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mongo_dart/mongo_dart.dart';

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

  // Cek Koneksi Internet
  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Tampilkan log dari Hive terlebih dahulu, lalu sinkronisasi dengan MongoDB jika online
  Future<List<LogModel>> getLogs() async {
    final box = Hive.box<LogModel>('logbook_box');

    final localData = box.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;

    if (await _isOnline()) {
      try {
        final remoteData = await MongoService().getLogsByUser(_username);

        // Agar data tidak duplikat
        for (final log in remoteData) {
          if (log.id != null) {
            await box.put(log.id!, log.copyWith(isSynced: true));
          }
        }

        final mergedData = box.values.toList();
        logsNotifier.value = mergedData;
        filteredLogs.value = mergedData;

        // Push data yang belum ke sync ke MongoDB
        await _syncPendingLogs();

        await LogHelper.writeLog(
          "INFO: Fetch logs success for $_username",
          source: "log_controller.dart",
          level: 3,
        );

        return mergedData;
      } catch (e) {
        await LogHelper.writeLog(
          "ERROR: Fetch logs failed - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
    return box.values.toList();
  }

  // Semua log dengan isSynced=false akan dicoba push ke MongoDB
  Future<void> _syncPendingLogs() async {
    final box = Hive.box<LogModel>('logbook_box');
    final unsyncedLogs = box.values.where((log) => !log.isSynced).toList();

    for (final log in unsyncedLogs) {
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
      id: ObjectId().toHexString(),
      title: title,
      desc: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      username: _username,
      authorId: _currentUserId,
      teamId: 'default_team',
      isSynced: false,
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
      isSynced: false,
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

    if (log.id == null) return;

    final box = Hive.box<LogModel>('logbook_box');
    await box.delete(log.id);

    logsNotifier.value = logsNotifier.value
        .where((l) => l.id != log.id)
        .toList();
    filteredLogs.value = logsNotifier.value;

    if (await _isOnline()) {
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
