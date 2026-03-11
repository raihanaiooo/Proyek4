import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';

void main() {
  test(
    'RBAC Security Check: Private logs should NOT be visible to teammates',
    () {
      // 1. Setup Data: User A punya 2 catatan
      const userAId = 'user_A';
      const userBId = 'user_B';

      final privateLog = LogModel(
        id: 'aabbccddeeff00112233445501',
        title: 'Catatan Rahasia A',
        desc: 'Isi privat',
        date: DateTime.now().toIso8601String(),
        category: 'Pribadi',
        username: 'userA',
        authorId: userAId,
        teamId: 'team_alpha',
        isPublic: false,
      );

      final publicLog = LogModel(
        id: 'aabbccddeeff00112233445502',
        title: 'Pengumuman Tim',
        desc: 'Isi publik',
        date: DateTime.now().toIso8601String(),
        category: 'Pekerjaan',
        username: 'userA',
        authorId: userAId,
        teamId: 'team_alpha',
        isPublic: true,
      );

      final allLogs = [privateLog, publicLog];

      // 2. Action: User B filter log yang bisa dia lihat
      final visibleToUserB = allLogs.where((log) {
        return log.authorId == userBId || log.isPublic == true;
      }).toList();

      // 3. Assert
      expect(
        visibleToUserB.length,
        1,
        reason: 'User B hanya boleh melihat 1 log (yang Public)',
      );

      expect(
        visibleToUserB.first.title,
        'Pengumuman Tim',
        reason: 'Log yang terlihat harus yang berstatus Public',
      );

      expect(
        visibleToUserB.any((log) => log.title == 'Catatan Rahasia A'),
        isFalse,
        reason: 'Log Private milik User A TIDAK boleh terlihat oleh User B',
      );
    },
  );
}
