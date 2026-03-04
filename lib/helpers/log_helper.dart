import 'dart:developer' as dev;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;

    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    final mutedSources = muteList
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (mutedSources.contains(source)) return;
    if (level > configLevel) return;

    try {
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());

      String label = _getLabel(level);
      String color = _getColor(level);

      final logLine = "[$timestamp][$label][$source] -> $message";

      dev.log(message, name: source, time: DateTime.now(), level: level * 100);

      print('$color$logLine\x1B[0m');

      await _writeToFile(logLine);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static Future<void> _writeToFile(String content) async {
    final now = DateTime.now();

    final fileName =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}.log";

    final directory = await getExternalStorageDirectory();

    if (directory == null) {
      print("External storage tidak tersedia");
      return;
    }

    final logDir = Directory('${directory.path}/logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    final file = File('${logDir.path}/$fileName');

    await file.writeAsString(content + "\n", mode: FileMode.append);

    print("LOG FILE PATH: ${file.path}");
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
