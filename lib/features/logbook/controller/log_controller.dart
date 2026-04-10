// import 'package:flutter/material.dart';
// import 'package:hive/hive.dart';
// import 'package:mongo_dart/mongo_dart.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// import '../models/log_model.dart';
// import 'package:logbook_app_01/features/logbook/services/mongo_service.dart';
// import 'package:logbook_app_01/features/logbook/services/access_control_service.dart';
// import 'package:logbook_app_01/features/logbook/helpers/log_helper.dart';

// class LogController {
//   final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
//   final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

//   String _username = "User";
//   late String _currentUserId;
//   late String _currentUserRole;
//   late String _teamId;

//   Future<void> init(String username) async {
//     _username = username;
//   }

//   void setCurrentUser({
//     required String userId,
//     required String role,
//     required String teamId,
//   }) {
//     _currentUserId = userId;
//     _currentUserRole = role;
//     _teamId = teamId;
//   }

//   Future<bool> _isOnline() async {
//     final result = await Connectivity().checkConnectivity();
//     return result != ConnectivityResult.none;
//   }

//   Future<List<LogModel>> getLogs() async {
//     final box = Hive.box<LogModel>('logbook_box');
//     final localData = box.values.toList();
//     logsNotifier.value = localData;
//     filteredLogs.value = localData;

//     if (await _isOnline()) {
//       try {
//         // final remoteData = await MongoService().getLogsByUser(_username);
//         final remoteData = await MongoService().getLogsByTeam(_teamId);
//         for (final log in remoteData) {
//           if (log.id != null) {
//             await box.put(log.id!, log.copyWith(isSynced: true));
//           }
//         }
//         final mergedData = box.values.toList();
//         logsNotifier.value = mergedData;
//         filteredLogs.value = mergedData;
//         await _syncPendingLogs();
//         return mergedData;
//       } catch (e) {
//         await LogHelper.writeLog(
//           "WARN: Remote fetch failed, using local - $e",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       }
//     }
//     return box.values.toList();
//   }

//   Future<void> _syncPendingLogs() async {
//     final box = Hive.box<LogModel>('logbook_box');
//     final unsyncedLogs = box.values.where((log) => !log.isSynced).toList();

//     for (final log in unsyncedLogs) {
//       if (log.id == null || log.id!.length != 24) {
//         await box.delete(log.id);
//         await LogHelper.writeLog(
//           "CLEANUP: Hapus log dengan ID tidak valid: ${log.id}",
//           source: "log_controller.dart",
//           level: 2,
//         );
//         continue;
//       }

//       try {
//         await MongoService().insertLog(log);
//         await box.put(log.id!, log.copyWith(isSynced: true));

//         await LogHelper.writeLog(
//           "SYNC: Log ${log.id} berhasil dikirim ke MongoDB",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       } catch (e) {
//         await LogHelper.writeLog(
//           "SYNC ERROR: Gagal sync log ${log.id} - $e",
//           source: "log_controller.dart",
//           level: 1,
//         );
//       }
//     }

//     logsNotifier.value = box.values.toList();
//     filteredLogs.value = logsNotifier.value;
//   }

//   void searchLog(String query) {
//     if (query.isEmpty) {
//       filteredLogs.value = logsNotifier.value;
//     } else {
//       filteredLogs.value = logsNotifier.value
//           .where(
//             (log) =>
//                 log.title.toLowerCase().contains(query.toLowerCase()) ||
//                 log.desc.toLowerCase().contains(query.toLowerCase()),
//           )
//           .toList();
//     }
//   }

//   Future<void> addLog(
//     String title,
//     String desc,
//     String category, {
//     bool isPublic = false,
//   }) async {
//     final newLog = LogModel(
//       id: ObjectId().toHexString(),
//       title: title,
//       desc: desc,
//       date: DateTime.now().toIso8601String(),
//       category: category,
//       username: _username,
//       authorId: _currentUserId,
//       teamId: _teamId,
//       isSynced: false,
//       isPublic: isPublic,
//     );

//     final box = Hive.box<LogModel>('logbook_box');
//     await box.put(newLog.id!, newLog);

//     logsNotifier.value = [...logsNotifier.value, newLog];
//     filteredLogs.value = logsNotifier.value;

//     if (await _isOnline()) {
//       try {
//         await MongoService().insertLog(newLog);
//         await box.put(newLog.id!, newLog.copyWith(isSynced: true));

//         logsNotifier.value = box.values.toList();
//         filteredLogs.value = logsNotifier.value;

//         await LogHelper.writeLog(
//           "SUCCESS: Log added & synced to MongoDB",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       } catch (e) {
//         await LogHelper.writeLog(
//           "OFFLINE: Log saved locally, will sync later - $e",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       }
//     } else {
//       await LogHelper.writeLog(
//         "OFFLINE: Log saved locally only (no connection)",
//         source: "log_controller.dart",
//         level: 2,
//       );
//     }
//   }

//   Future<void> updateLog(
//     LogModel log,
//     String title,
//     String desc,
//     String category, {
//     bool? isPublic,
//   }) async {
//     final updatedLog = LogModel(
//       id: log.id,
//       title: title,
//       desc: desc,
//       date: DateTime.now().toIso8601String(),
//       category: category,
//       username: _username,
//       authorId: log.authorId,
//       teamId: log.teamId,
//       isSynced: false,
//       isPublic: isPublic ?? log.isPublic,
//     );

//     final box = Hive.box<LogModel>('logbook_box');
//     await box.put(updatedLog.id!, updatedLog);

//     logsNotifier.value = box.values.toList();
//     filteredLogs.value = logsNotifier.value;

//     if (await _isOnline()) {
//       try {
//         await MongoService().updateLog(updatedLog);
//         await box.put(updatedLog.id!, updatedLog.copyWith(isSynced: true));

//         logsNotifier.value = box.values.toList();
//         filteredLogs.value = logsNotifier.value;

//         await LogHelper.writeLog(
//           "SUCCESS: Log updated & synced",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       } catch (e) {
//         await LogHelper.writeLog(
//           "OFFLINE: Update saved locally, will sync later - $e",
//           source: "log_controller.dart",
//           level: 1,
//         );
//       }
//     }
//   }

//   // Task 5: Hanya owner yang bisa hapus, role tidak relevan
//   Future<void> removeLog(LogModel log) async {
//     final isOwner = log.authorId == _currentUserId;

//     if (!isOwner) {
//       await LogHelper.writeLog(
//         "SECURITY: Delete denied for $_currentUserId (bukan pemilik)",
//         source: "log_controller.dart",
//         level: 1,
//       );
//       throw Exception(
//         "Akses ditolak: Hanya pemilik catatan yang dapat menghapus.",
//       );
//     }

//     if (log.id == null) return;

//     final box = Hive.box<LogModel>('logbook_box');
//     await box.delete(log.id);

//     logsNotifier.value = logsNotifier.value
//         .where((l) => l.id != log.id)
//         .toList();
//     filteredLogs.value = logsNotifier.value;

//     if (await _isOnline()) {
//       if (log.id!.length != 24) return;

//       try {
//         await MongoService().deleteLog(log.id!);

//         await LogHelper.writeLog(
//           "SUCCESS: Log deleted from local & MongoDB",
//           source: "log_controller.dart",
//           level: 2,
//         );
//       } catch (e) {
//         await LogHelper.writeLog(
//           "OFFLINE: Deleted locally, MongoDB delete pending - $e",
//           source: "log_controller.dart",
//           level: 1,
//         );
//       }
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_model.dart';
import 'package:logbook_app_01/features/logbook/services/mongo_service.dart';
import 'package:logbook_app_01/features/logbook/services/access_control_service.dart';
import 'package:logbook_app_01/features/logbook/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);

  // Dependency injection — opsional, default pakai instance asli
  final MongoService _mongoService;
  final Connectivity _connectivity;

  // Flag untuk skip LogHelper (dotenv) saat test
  final bool skipLog;

  LogController({
    MongoService? mongoService,
    Connectivity? connectivity,
    this.skipLog = false,
  }) : _mongoService = mongoService ?? MongoService(),
       _connectivity = connectivity ?? Connectivity();

  String _username = "User";
  late String _currentUserId;
  late String _currentUserRole;
  late String _teamId;

  // SharedPreferences keys
  static const String _keyDraftTitle = 'log_draft_title';
  static const String _keyDraftDesc = 'log_draft_desc';
  static const String _keyLastFilter = 'log_last_filter';
  static const String _keyLastSearch = 'log_last_search';

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

  // ─── Helper internal ──────────────────────────────────────────────────────────

  Future<void> _log(
    String message, {
    required String source,
    required int level,
  }) async {
    if (skipLog) return; // skip saat test agar dotenv tidak error
    await LogHelper.writeLog(message, source: source, level: level);
  }

  // ─── SharedPreferences: Draft ────────────────────────────────────────────────

  Future<void> saveDraft(String title, String desc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDraftTitle, title);
    await prefs.setString(_keyDraftDesc, desc);
  }

  Future<Map<String, String?>> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'title': prefs.getString(_keyDraftTitle),
      'desc': prefs.getString(_keyDraftDesc),
    };
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftTitle);
    await prefs.remove(_keyDraftDesc);
  }

  // ─── SharedPreferences: Last Filter ──────────────────────────────────────────

  Future<void> saveLastFilter(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastFilter, category);
  }

  Future<String?> loadLastFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastFilter);
  }

  // ─── SharedPreferences: Last Search Query ─────────────────────────────────────

  Future<void> saveLastSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSearch, query);
  }

  Future<String?> loadLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastSearch);
  }

  // ─── Connectivity ─────────────────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ─── Hive + MongoDB ───────────────────────────────────────────────────────────

  Future<List<LogModel>> getLogs() async {
    final box = Hive.box<LogModel>('logbook_box');
    final localData = box.values.toList();
    logsNotifier.value = localData;
    filteredLogs.value = localData;

    if (await _isOnline()) {
      try {
        final remoteData = await _mongoService.getLogsByTeam(_teamId);
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
        await _log(
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
        await _log(
          "CLEANUP: Hapus log dengan ID tidak valid: ${log.id}",
          source: "log_controller.dart",
          level: 2,
        );
        continue;
      }

      try {
        await _mongoService.insertLog(log);
        await box.put(log.id!, log.copyWith(isSynced: true));
        await _log(
          "SYNC: Log ${log.id} berhasil dikirim ke MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await _log(
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
        await _mongoService.insertLog(newLog);
        await box.put(newLog.id!, newLog.copyWith(isSynced: true));
        logsNotifier.value = box.values.toList();
        filteredLogs.value = logsNotifier.value;
        await _log(
          "SUCCESS: Log added & synced to MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await _log(
          "OFFLINE: Log saved locally, will sync later - $e",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } else {
      await _log(
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
        await _mongoService.updateLog(updatedLog);
        await box.put(updatedLog.id!, updatedLog.copyWith(isSynced: true));
        logsNotifier.value = box.values.toList();
        filteredLogs.value = logsNotifier.value;
        await _log(
          "SUCCESS: Log updated & synced",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await _log(
          "OFFLINE: Update saved locally, will sync later - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
  }

  Future<void> removeLog(LogModel log) async {
    final isOwner = log.authorId == _currentUserId;

    if (!isOwner) {
      await _log(
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
        await _mongoService.deleteLog(log.id!);
        await _log(
          "SUCCESS: Log deleted from local & MongoDB",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        await _log(
          "OFFLINE: Deleted locally, MongoDB delete pending - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }
  }
}
