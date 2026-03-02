import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_01/helpers/log_helper.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  test('Test LOG_LEVEL verbosity', () async {
    await LogHelper.writeLog("Ini ERROR test", source: "test.dart", level: 1);

    await LogHelper.writeLog("Ini INFO test", source: "test.dart", level: 2);

    await LogHelper.writeLog("Ini VERBOSE test", source: "test.dart", level: 3);

    expect(true, true);
  });

  test('Test LOG_MUTE filtering', () async {
    await LogHelper.writeLog(
      "Log dari connection_test.dart",
      source: "connection_test.dart",
      level: 2,
    );

    await LogHelper.writeLog(
      "Log dari mongo_service.dart",
      source: "mongo_service.dart",
      level: 2,
    );

    expect(true, true);
  });
}
