import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_01/features/logbook/controller/counter_controller.dart';

void main() {
  var actual, expected;

  group('Module 1 - CounterController (with storage & step)', () {
    late CounterController controller;
    const username = "admin";

    setUp(() async {
      // (1) setup (arrange, build)
      SharedPreferences.setMockInitialValues({}); // mock storage
      controller = CounterController();
      await controller.init(username); // load initial value & history
    });

    // TC01
    test('initial value should be 0', () {
      // (2) exercise (act, operate)
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC02
    test('increment should increase counter based on input', () async {
      // (2) exercise (act, operate)
      await controller.increment('3');
      actual = controller.value;
      expected = 3;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC03
    test('increment should ignore invalid input', () async {
      // (1) setup (arrange, build)
      await controller.increment('5'); // counter = 5

      // (2) exercise (act, operate)
      await controller.increment('abc'); // input tidak valid, diabaikan
      actual = controller.value;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC04
    test('decrement should decrease counter based on input', () async {
      // (1) setup (arrange, build)
      await controller.increment('10'); // counter = 10

      // (2) exercise (act, operate)
      await controller.decrement('3');
      actual = controller.value;
      expected = 7;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC05
    test('decrement should not run when counter is 1 or less', () async {
      // (1) setup (arrange, build)
      // counter awal = 0 (dari init), tidak di-increment
      // counter = 0 (tidak masuk kondisi _step > 1)

      // (2) exercise (act, operate)
      await controller.decrement('1');
      actual = controller.value;
      expected = 0;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC06
    test('decrement should ignore invalid input', () async {
      // (1) setup (arrange, build)
      await controller.increment('5'); // counter = 5

      // (2) exercise (act, operate)
      await controller.decrement('-3'); // input negatif, diabaikan
      actual = controller.value;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC07
    test('reset should set counter to 1', () async {
      // (1) setup (arrange, build)
      await controller.increment('10'); // counter = 10

      // (2) exercise (act, operate)
      await controller.reset();
      actual = controller.value;
      expected = 1;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC08
    test('history should record actions', () async {
      // (1) setup (arrange, build)
      // controller sudah di-init di setUp

      // (2) exercise (act, operate)
      await controller.increment('2');
      var actual1 = controller.history.isNotEmpty;
      var expected1 = true;
      var actual2 = controller.history.first.contains(
        "menambah nilai sebesar 2",
      );
      var expected2 = true;

      // (3) verify (assert, check)
      expect(
        actual1,
        expected1,
        reason: 'Expected $expected1 but got $actual1',
      );
      expect(
        actual2,
        expected2,
        reason: 'Expected $expected2 but got $actual2',
      );
    });

    // TC09
    test('history should not exceed 5 items', () async {
      // (1) setup (arrange, build)
      // controller sudah di-init di setUp

      // (2) exercise (act, operate)
      for (int i = 0; i < 6; i++) {
        await controller.increment('1');
      }
      actual = controller.history.length;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC10
    test('getGreeting should return correct greeting based on hour', () {
      // (1) setup (arrange, build)
      final loginPagi = DateTime(2024, 1, 1, 10, 0); // jam 10

      // (2) exercise (act, operate)
      actual = controller.getGreeting(username: username, login: loginPagi);
      expected = "Selamat Pagi, admin!";

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC11
    test('increment should ignore zero input', () async {
      // (1) setup (arrange, build)
      await controller.increment('5'); // counter = 5

      // (2) exercise (act, operate)
      await controller.increment('0'); // input nol, diabaikan
      actual = controller.value;
      expected = 5;

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC12
    test('decrement result should not go below zero', () async {
      // (1) setup (arrange, build)
      await controller.increment('3'); // counter = 3

      // (2) exercise (act, operate)
      await controller.decrement('10'); // input melebihi nilai counter
      actual = controller.value;
      expected = greaterThanOrEqualTo(0);

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected counter >= 0 but got $actual');
    });

    // TC13
    test('getGreeting should return Selamat Siang for afternoon hour', () {
      // (1) setup (arrange, build)
      final loginSiang = DateTime(2024, 1, 1, 13, 0); // jam 13

      // (2) exercise (act, operate)
      actual = controller.getGreeting(username: username, login: loginSiang);
      expected = "Selamat Siang, admin!";

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC14
    test('getGreeting should return Selamat Sore for evening hour', () {
      // (1) setup (arrange, build)
      final loginSore = DateTime(2024, 1, 1, 17, 0); // jam 17

      // (2) exercise (act, operate)
      actual = controller.getGreeting(username: username, login: loginSore);
      expected = "Selamat Sore, admin!";

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });

    // TC15
    test('getGreeting should return Selamat Malam for night hour', () {
      // (1) setup (arrange, build)
      final loginMalam = DateTime(2024, 1, 1, 22, 0); // jam 22

      // (2) exercise (act, operate)
      actual = controller.getGreeting(username: username, login: loginMalam);
      expected = "Selamat Malam, admin!";

      // (3) verify (assert, check)
      expect(actual, expected, reason: 'Expected $expected but got $actual');
    });
  });
}
