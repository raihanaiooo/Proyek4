import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_01/features/logbook/controller/auth/login_controller.dart';

void main() {
  var actual, expected;

  group('Module 2 - LoginController (Authentication)', () {
    late LoginController controller;

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({}); // mock storage
      controller = LoginController();
    });

    // TC01
    test(
      'login should return UserData with role Ketua when credentials are valid',
      () {
        // (2) exercise (act, operate)
        actual = controller.login('ketua', 'ketua123');
        expected = 'Ketua';

        // (3) verify (assert, check)
        expect(
          actual,
          isNotNull,
          reason: 'Expected user to be found but got null',
        );
        expect(
          actual?.role,
          expected,
          reason: 'Expected role $expected but got ${actual?.role}',
        );
        expect(
          actual?.userId,
          'user_001',
          reason: 'Expected userId user_001 but got ${actual?.userId}',
        );
        expect(
          actual?.teamId,
          'team_alpha',
          reason: 'Expected teamId team_alpha but got ${actual?.teamId}',
        );
      },
    );

    // TC02
    test(
      'login should return UserData with role Anggota when credentials are valid',
      () {
        // (2) exercise (act, operate)
        actual = controller.login('anggota', 'anggota123');
        expected = 'Anggota';

        // (3) verify (assert, check)
        expect(
          actual,
          isNotNull,
          reason: 'Expected user to be found but got null',
        );
        expect(
          actual?.role,
          expected,
          reason: 'Expected role $expected but got ${actual?.role}',
        );
        expect(
          actual?.userId,
          'user_002',
          reason: 'Expected userId user_002 but got ${actual?.userId}',
        );
        expect(
          actual?.teamId,
          'team_alpha',
          reason: 'Expected teamId team_alpha but got ${actual?.teamId}',
        );
      },
    );

    // TC03
    test(
      'login should return UserData with role Asisten when credentials are valid',
      () {
        // (2) exercise (act, operate)
        actual = controller.login('asisten', 'asisten123');
        expected = 'Asisten';

        // (3) verify (assert, check)
        expect(
          actual,
          isNotNull,
          reason: 'Expected user to be found but got null',
        );
        expect(
          actual?.role,
          expected,
          reason: 'Expected role $expected but got ${actual?.role}',
        );
        expect(
          actual?.userId,
          'user_003',
          reason: 'Expected userId user_003 but got ${actual?.userId}',
        );
        expect(
          actual?.teamId,
          'team_alpha',
          reason: 'Expected teamId team_alpha but got ${actual?.teamId}',
        );
      },
    );

    // TC04
    test('login should return null when password is wrong', () {
      // (2) exercise (act, operate)
      actual = controller.login('ketua', 'salah123');
      expected = null;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected null but got $actual');
    });

    // TC05
    test('login should return null when username is not found', () {
      // (2) exercise (act, operate)
      actual = controller.login('tidakada', 'bebas123');
      expected = null;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected null but got $actual');
    });

    // TC06
    test('login should return null when username and password are empty', () {
      // (2) exercise (act, operate)
      actual = controller.login('', '');
      expected = null;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected null but got $actual');
    });

    // TC07
    test(
      'saveCurrentUser should store all user data to SharedPreferences',
      () async {
        // (1) setup (arrange, build)
        final user = controller.login('ketua', 'ketua123');

        // (2) exercise (act, operate)
        await controller.saveCurrentUser(user!);
        actual = await controller.getSavedSession();

        // (3) verify (assert, check)
        expect(
          actual['username'],
          'ketua',
          reason: 'Expected username ketua but got ${actual['username']}',
        );
        expect(
          actual['userId'],
          'user_001',
          reason: 'Expected userId user_001 but got ${actual['userId']}',
        );
        expect(
          actual['role'],
          'Ketua',
          reason: 'Expected role Ketua but got ${actual['role']}',
        );
        expect(
          actual['teamId'],
          'team_alpha',
          reason: 'Expected teamId team_alpha but got ${actual['teamId']}',
        );
      },
    );

    // TC08
    test('saveCurrentUser should overwrite previous session data', () async {
      // (1) setup (arrange, build)
      final userKetua = controller.login('ketua', 'ketua123');
      await controller.saveCurrentUser(userKetua!);

      // (2) exercise (act, operate)
      final userAnggota = controller.login('anggota', 'anggota123');
      await controller.saveCurrentUser(userAnggota!);
      actual = await controller.getSavedSession();

      // (3) verify (assert, check)
      expect(
        actual['username'],
        'anggota',
        reason: 'Expected username anggota but got ${actual['username']}',
      );
      expect(
        actual['userId'],
        'user_002',
        reason: 'Expected userId user_002 but got ${actual['userId']}',
      );
      expect(
        actual['role'],
        'Anggota',
        reason: 'Expected role Anggota but got ${actual['role']}',
      );
    });

    // TC09
    test(
      'getSavedSession should return correct session data after saveCurrentUser',
      () async {
        // (1) setup (arrange, build)
        final user = controller.login('ketua', 'ketua123');
        await controller.saveCurrentUser(user!);

        // (2) exercise (act, operate)
        actual = await controller.getSavedSession();

        // (3) verify (assert, check)
        expect(
          actual['username'],
          'ketua',
          reason: 'Expected username ketua but got ${actual['username']}',
        );
        expect(
          actual['role'],
          'Ketua',
          reason: 'Expected role Ketua but got ${actual['role']}',
        );
        expect(
          actual['userId'],
          'user_001',
          reason: 'Expected userId user_001 but got ${actual['userId']}',
        );
        expect(
          actual['teamId'],
          'team_alpha',
          reason: 'Expected teamId team_alpha but got ${actual['teamId']}',
        );
      },
    );

    // TC10
    test(
      'getSavedSession should return all null values when no session is saved',
      () async {
        // (2) exercise (act, operate)
        actual = await controller.getSavedSession();

        // (3) verify (assert, check)
        expect(
          actual['username'],
          isNull,
          reason: 'Expected null but got ${actual['username']}',
        );
        expect(
          actual['userId'],
          isNull,
          reason: 'Expected null but got ${actual['userId']}',
        );
        expect(
          actual['role'],
          isNull,
          reason: 'Expected null but got ${actual['role']}',
        );
        expect(
          actual['teamId'],
          isNull,
          reason: 'Expected null but got ${actual['teamId']}',
        );
      },
    );

    // TC11
    test(
      'logout should remove all session data from SharedPreferences',
      () async {
        // (1) setup (arrange, build)
        final user = controller.login('ketua', 'ketua123');
        await controller.saveCurrentUser(user!);

        // (2) exercise (act, operate)
        await controller.logout();
        actual = await controller.getSavedSession();

        // (3) verify (assert, check)
        expect(
          actual['username'],
          isNull,
          reason: 'Expected null after logout but got ${actual['username']}',
        );
        expect(
          actual['userId'],
          isNull,
          reason: 'Expected null after logout but got ${actual['userId']}',
        );
        expect(
          actual['role'],
          isNull,
          reason: 'Expected null after logout but got ${actual['role']}',
        );
        expect(
          actual['teamId'],
          isNull,
          reason: 'Expected null after logout but got ${actual['teamId']}',
        );
      },
    );

    // TC12
    test('logout should not throw error when no session exists', () async {
      // (2) exercise (act, operate)
      // tidak ada sesi tersimpan sebelumnya
      await expectLater(controller.logout(), completes);
      actual = await controller.getSavedSession();

      // (3) verify (assert, check)
      expect(
        actual['username'],
        isNull,
        reason: 'Expected null but got ${actual['username']}',
      );
      expect(
        actual['userId'],
        isNull,
        reason: 'Expected null but got ${actual['userId']}',
      );
      expect(
        actual['role'],
        isNull,
        reason: 'Expected null but got ${actual['role']}',
      );
      expect(
        actual['teamId'],
        isNull,
        reason: 'Expected null but got ${actual['teamId']}',
      );
    });
  });
}
