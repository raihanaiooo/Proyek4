import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_test/hive_test.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:logbook_app_01/features/logbook/controller/log_controller.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';
import 'package:logbook_app_01/features/logbook/services/mongo_service.dart';

@GenerateMocks([MongoService, Connectivity])
import 'modul4_saveToCloud_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var actual, expected;

  group('Module 4 - LogController (Save Data to Cloud Service)', () {
    late LogController controller;
    late MockMongoService mockMongo;
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

      mockMongo = MockMongoService();
      mockConnectivity = MockConnectivity();

      // Default: mock online
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      controller = LogController(
        mongoService: mockMongo,
        connectivity: mockConnectivity,
        skipLog: true,
      );
      controller.setCurrentUser(userId: userId, role: 'Ketua', teamId: teamId);
      await controller.init('admin');
    });

    tearDown(() async {
      if (box.isOpen) await box.close();
      await tearDownTestHive();
    });

    // TC01 — addLog positif: online + MongoDB sukses
    test(
      'addLog should save log to Hive and sync to MongoDB when online',
      () async {
        // (1) setup (arrange, build)
        when(mockMongo.insertLog(any)).thenAnswer((_) async {});

        // (2) exercise (act, operate)
        await controller.addLog('Test', 'Desc', 'Daily', isPublic: false);
        actual = box.values.toList();

        // (3) verify (assert, check)
        expect(actual, isNotEmpty, reason: 'Expected log to be saved in Hive');
        expect(
          actual.first.title,
          'Test',
          reason: 'Expected title Test but got ${actual.first.title}',
        );
        verify(mockMongo.insertLog(any)).called(1);
      },
    );

    // TC02 — addLog negatif: online + MongoDB error (fallback)
    test(
      'addLog should save log locally with isSynced false when MongoDB throws error',
      () async {
        // (1) setup (arrange, build)
        when(mockMongo.insertLog(any)).thenThrow(Exception('MongoDB error'));

        // (2) exercise (act, operate)
        await controller.addLog('Test', 'Desc', 'Daily');
        actual = box.values.toList();

        // (3) verify (assert, check)
        expect(
          actual,
          isNotEmpty,
          reason: 'Expected log to be saved locally as fallback',
        );
        expect(
          actual.first.isSynced,
          isFalse,
          reason: 'Expected isSynced false after MongoDB error',
        );
      },
    );

    // TC03 — addLog negatif: offline (MongoDB tidak dipanggil)
    test('addLog should save log locally only when offline', () async {
      // (1) setup (arrange, build)
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      ); // override ke offline

      // (2) exercise (act, operate)
      await controller.addLog('Offline Log', 'Desc', 'Daily');
      actual = box.values.toList();

      // (3) verify (assert, check)
      expect(actual, isNotEmpty, reason: 'Expected log to be saved locally');
      expect(
        actual.first.isSynced,
        isFalse,
        reason: 'Expected isSynced false when offline',
      );
      verifyNever(mockMongo.insertLog(any));
    });

    // TC04
    test(
      'updateLog should update log in Hive and sync to MongoDB when online',
      () async {
        // (1) setup (arrange, build)
        final log = makeLog(title: 'Old Title');
        await box.put(log.id!, log);
        when(mockMongo.updateLog(any)).thenAnswer((_) async {});

        // (2) exercise (act, operate)
        await controller.updateLog(
          log,
          'Updated Title',
          'Updated Desc',
          'Daily',
        );
        actual = box.get(log.id!)?.title;
        expected = 'Updated Title';

        // (3) verify (assert, check)
        expect(
          actual,
          expected,
          reason: 'Expected title $expected but got $actual',
        );
        verify(mockMongo.updateLog(any)).called(1);
      },
    );

    // TC05
    test(
      'updateLog should save update locally with isSynced false when MongoDB throws error',
      () async {
        // (1) setup (arrange, build)
        final log = makeLog(title: 'Old Title');
        await box.put(log.id!, log);
        when(mockMongo.updateLog(any)).thenThrow(Exception('MongoDB error'));

        // (2) exercise (act, operate)
        await controller.updateLog(
          log,
          'Updated Title',
          'Updated Desc',
          'Daily',
        );
        actual = box.get(log.id!);

        // (3) verify (assert, check)
        expect(
          actual?.title,
          'Updated Title',
          reason: 'Expected title to be updated locally',
        );
        expect(
          actual?.isSynced,
          isFalse,
          reason: 'Expected isSynced false but got ${actual?.isSynced}',
        );
      },
    );

    // TC06
    test(
      'removeLog should delete log from Hive and call MongoDB delete when user is owner',
      () async {
        // (1) setup (arrange, build)
        final log = makeLog(authorId: userId);
        await box.put(log.id!, log);
        controller.logsNotifier.value = [log];
        when(mockMongo.deleteLog(any)).thenAnswer((_) async {});

        // (2) exercise (act, operate)
        await controller.removeLog(log);
        actual = box.get(log.id!);

        // (3) verify (assert, check)
        expect(actual, isNull, reason: 'Expected log to be deleted from Hive');
        verify(mockMongo.deleteLog(log.id!)).called(1);
      },
    );

    // TC07
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
      verifyNever(mockMongo.deleteLog(any));
    });

    // TC08
    test(
      'removeLog should still delete from Hive when MongoDB throws error',
      () async {
        // (1) setup (arrange, build)
        final log = makeLog(authorId: userId);
        await box.put(log.id!, log);
        controller.logsNotifier.value = [log];
        when(mockMongo.deleteLog(any)).thenThrow(Exception('MongoDB error'));

        // (2) exercise (act, operate)
        await controller.removeLog(log);
        actual = box.get(log.id!);

        // (3) verify (assert, check)
        expect(
          actual,
          isNull,
          reason: 'Expected log deleted from Hive even when MongoDB fails',
        );
      },
    );

    // TC09
    test(
      'getLogs should return merged data from Hive and MongoDB when online',
      () async {
        // (1) setup (arrange, build)
        final log1 = makeLog(id: 'aabbccddeeff001122334401', title: 'Log 1');
        final log2 = makeLog(id: 'aabbccddeeff001122334402', title: 'Log 2');
        await box.put(log1.id!, log1);
        when(
          mockMongo.getLogsByTeam(teamId),
        ).thenAnswer((_) async => [log1, log2]);

        // (2) exercise (act, operate)
        await controller.getLogs();
        actual = controller.logsNotifier.value;

        // (3) verify (assert, check)
        expect(
          actual,
          isNotEmpty,
          reason: 'Expected logs to be returned but got empty',
        );
        verify(mockMongo.getLogsByTeam(teamId)).called(1);
      },
    );

    // TC10
    test(
      'getLogs should fallback to local Hive data when MongoDB throws error',
      () async {
        // (1) setup (arrange, build)
        final log1 = makeLog(id: 'aabbccddeeff001122334401', title: 'Log 1');
        final log2 = makeLog(id: 'aabbccddeeff001122334402', title: 'Log 2');
        await box.put(log1.id!, log1);
        await box.put(log2.id!, log2);
        when(
          mockMongo.getLogsByTeam(teamId),
        ).thenThrow(Exception('MongoDB error'));

        // (2) exercise (act, operate)
        await controller.getLogs();
        actual = controller.logsNotifier.value.length;
        expected = 2;

        // (3) verify (assert, check)
        expect(
          actual,
          expected,
          reason: 'Expected $expected local logs as fallback but got $actual',
        );
      },
    );

    // TC11
    test('getLogs should return local data when offline', () async {
      // (1) setup (arrange, build)
      when(mockConnectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none],
      ); // override ke offline
      final log1 = makeLog(id: 'aabbccddeeff001122334401', title: 'Log 1');
      await box.put(log1.id!, log1);

      // (2) exercise (act, operate)
      await controller.getLogs();
      actual = controller.logsNotifier.value;

      // (3) verify (assert, check)
      expect(
        actual,
        isNotEmpty,
        reason: 'Expected logsNotifier to have local data',
      );
      verifyNever(mockMongo.getLogsByTeam(any));
    });
  });
}
