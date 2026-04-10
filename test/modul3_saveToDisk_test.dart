import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_test/hive_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:logbook_app_01/features/logbook/controller/log_controller.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';

@GenerateMocks([Connectivity])
import 'modul3_saveToDisk_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var actual, expected;

  group('Module 3 - LogController (Save Data to Disk)', () {
    late LogController controller;
    late MockConnectivity mockConnectivity;
    late Box<LogModel> box;

    const userId = 'user_001';
    const teamId = 'team_alpha';

    LogModel makeLog({
      String id = 'aabbccddeeff001122334455',
      String title = 'Test Log',
      String desc = 'Desc',
      String category = 'Daily',
      String authorId = userId,
      bool isSynced = false,
      bool isPublic = false,
    }) {
      return LogModel(
        id: id,
        title: title,
        desc: desc,
        date: DateTime.now().toIso8601String(),
        category: category,
        username: 'admin',
        authorId: authorId,
        teamId: teamId,
        isSynced: isSynced,
        isPublic: isPublic,
      );
    }

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({});
      await setUpTestHive();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LogModelAdapter());
      }
      box = await Hive.openBox<LogModel>('logbook_box');

      mockConnectivity = MockConnectivity();

      // Default: mock offline agar Hive test tidak perlu MongoDB
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      controller = LogController(
        connectivity: mockConnectivity,
        skipLog: true, // skip dotenv/LogHelper
      );
      controller.setCurrentUser(userId: userId, role: 'Ketua', teamId: teamId);
      await controller.init('admin');
    });

    tearDown(() async {
      if (box.isOpen) await box.close();
      await tearDownTestHive();
    });

    // ─── Hive Tests ───────────────────────────────────────────────────────────────

    // TC01
    test('addLog should save log to Hive box', () async {
      // (2) exercise (act, operate)
      await controller.addLog('Test Log', 'Desc', 'Daily');
      actual = box.values.toList();

      // (3) verify (assert, check)
      expect(
        actual,
        isNotEmpty,
        reason: 'Expected log to be saved in Hive but box is empty',
      );
      expect(
        actual.first.title,
        'Test Log',
        reason: 'Expected title Test Log but got ${actual.first.title}',
      );
    });

    // TC02
    test('addLog should set isSynced to false when saved to Hive', () async {
      // (2) exercise (act, operate)
      await controller.addLog('Test Log', 'Desc', 'Daily');
      actual = box.values.first.isSynced;
      expected = false;

      // (3) verify (assert, check)
      expect(
        actual,
        expected,
        reason: 'Expected isSynced false but got $actual',
      );
    });

    // TC03
    test('updateLog should update existing log data in Hive', () async {
      // (1) setup (arrange, build)
      final log = makeLog(title: 'Old Title');
      await box.put(log.id!, log);

      // (2) exercise (act, operate)
      await controller.updateLog(log, 'New Title', 'New Desc', 'Weekly');
      actual = box.get(log.id!)?.title;
      expected = 'New Title';

      // (3) verify (assert, check)
      expect(
        actual,
        expected,
        reason: 'Expected title New Title but got $actual',
      );
    });

    // TC04
    test('removeLog should delete log from Hive when user is owner', () async {
      // (1) setup (arrange, build)
      final log = makeLog(authorId: userId);
      await box.put(log.id!, log);
      controller.logsNotifier.value = [log];

      // (2) exercise (act, operate)
      await controller.removeLog(log);
      actual = box.get(log.id!);

      // (3) verify (assert, check)
      expect(
        actual,
        isNull,
        reason: 'Expected log to be deleted from Hive but still exists',
      );
    });

    // TC05
    test('removeLog should throw exception when user is not owner', () async {
      // (1) setup (arrange, build)
      final log = makeLog(authorId: 'user_other');
      await box.put(log.id!, log);
      controller.logsNotifier.value = [log];

      // (2) exercise (act, operate) & verify (assert, check)
      await expectLater(
        () async => await controller.removeLog(log),
        throwsA(
          predicate(
            (e) => e is Exception && e.toString().contains('Akses ditolak'),
          ),
        ),
        reason: 'Expected exception Akses ditolak but none was thrown',
      );
    });

    // TC06
    test('searchLog should filter logs by query from logsNotifier', () async {
      // (1) setup (arrange, build)
      controller.logsNotifier.value = [
        makeLog(id: 'id1', title: 'flutter dasar'),
        makeLog(id: 'id2', title: 'dart basics'),
        makeLog(id: 'id3', title: 'flutter lanjut'),
      ];

      // (2) exercise (act, operate)
      controller.searchLog('flutter');
      actual = controller.filteredLogs.value.length;
      expected = 2;

      // (3) verify (assert, check)
      expect(
        actual,
        expected,
        reason: 'Expected $expected results but got $actual',
      );
    });

    // TC07
    test('searchLog should return all logs when query is empty', () async {
      // (1) setup (arrange, build)
      controller.logsNotifier.value = [
        makeLog(id: 'id1', title: 'flutter dasar'),
        makeLog(id: 'id2', title: 'dart basics'),
        makeLog(id: 'id3', title: 'hive storage'),
      ];

      // (2) exercise (act, operate)
      controller.searchLog('');
      actual = controller.filteredLogs.value.length;
      expected = 3;

      // (3) verify (assert, check)
      expect(
        actual,
        expected,
        reason: 'Expected $expected logs but got $actual',
      );
    });

    // TC08
    test(
      'searchLog should return empty list when no log matches query',
      () async {
        // (1) setup (arrange, build)
        controller.logsNotifier.value = [
          makeLog(id: 'id1', title: 'flutter dasar'),
          makeLog(id: 'id2', title: 'dart basics'),
        ];

        // (2) exercise (act, operate)
        controller.searchLog('xyz');
        actual = controller.filteredLogs.value.length;
        expected = 0;

        // (3) verify (assert, check)
        expect(
          actual,
          expected,
          reason: 'Expected $expected results but got $actual',
        );
      },
    );

    // ─── SharedPreferences Tests ──────────────────────────────────────────────────

    // TC09
    test(
      'saveDraft should store title and desc to SharedPreferences',
      () async {
        // (2) exercise (act, operate)
        await controller.saveDraft('Draft Title', 'Draft Desc');
        actual = await controller.loadDraft();

        // (3) verify (assert, check)
        expect(
          actual['title'],
          'Draft Title',
          reason: 'Expected title Draft Title but got ${actual['title']}',
        );
        expect(
          actual['desc'],
          'Draft Desc',
          reason: 'Expected desc Draft Desc but got ${actual['desc']}',
        );
      },
    );

    // TC10
    test(
      'loadDraft should return null values when no draft is saved',
      () async {
        // (2) exercise (act, operate)
        actual = await controller.loadDraft();

        // (3) verify (assert, check)
        expect(
          actual['title'],
          isNull,
          reason: 'Expected null but got ${actual['title']}',
        );
        expect(
          actual['desc'],
          isNull,
          reason: 'Expected null but got ${actual['desc']}',
        );
      },
    );

    // TC11
    test('clearDraft should remove draft from SharedPreferences', () async {
      // (1) setup (arrange, build)
      await controller.saveDraft('Draft Title', 'Draft Desc');

      // (2) exercise (act, operate)
      await controller.clearDraft();
      actual = await controller.loadDraft();

      // (3) verify (assert, check)
      expect(
        actual['title'],
        isNull,
        reason: 'Expected null after clearDraft but got ${actual['title']}',
      );
      expect(
        actual['desc'],
        isNull,
        reason: 'Expected null after clearDraft but got ${actual['desc']}',
      );
    });

    // TC12
    test('saveLastFilter should store category to SharedPreferences', () async {
      // (2) exercise (act, operate)
      await controller.saveLastFilter('Weekly');
      actual = await controller.loadLastFilter();
      expected = 'Weekly';

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC13
    test('loadLastFilter should return null when no filter is saved', () async {
      // (2) exercise (act, operate)
      actual = await controller.loadLastFilter();

      // (3) verify (assert, check)
      expect(actual, isNull, reason: 'Expected null but got $actual');
    });

    // TC14
    test('saveLastSearch should store query to SharedPreferences', () async {
      // (2) exercise (act, operate)
      await controller.saveLastSearch('flutter');
      actual = await controller.loadLastSearch();
      expected = 'flutter';

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC15
    test('loadLastSearch should return null when no search is saved', () async {
      // (2) exercise (act, operate)
      actual = await controller.loadLastSearch();

      // (3) verify (assert, check)
      expect(actual, isNull, reason: 'Expected null but got $actual');
    });
  });
}
