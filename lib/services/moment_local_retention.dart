import 'dart:convert';
import 'local_owner_store.dart';

/// Housekeeping uses wall time; media authorization still uses backend time.
class MomentLocalRetention {
  MomentLocalRetention(this.local, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final LocalOwnerStore local;
  final DateTime Function() now;
  Future<void> remember(String uid, String eventId) async {
    if (await local.prefs.getString('active_owner') != uid) return;
    final key = '${local.prefix(uid)}moment_seen_$eventId';
    await local.prefs.setBool(key, true);
    await local.prefs.setInt(
      '${local.prefix(uid)}moment_seen_expiry_$eventId',
      now().add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    if (await local.prefs.getString('active_owner') != uid) {
      await local.prefs.remove(key);
      await local.prefs.remove(
        '${local.prefix(uid)}moment_seen_expiry_$eventId',
      );
    }
  }

  Future<int> prune(
    String uid, {
    Future<void> Function(int)? cancelNotice,
  }) async {
    if (await local.prefs.getString('active_owner') != uid) return 0;
    final all = await local.prefs.getAll(),
        prefix = local.prefix(uid),
        stamp = now().millisecondsSinceEpoch;
    var removed = 0;
    for (final entry in all.entries.where(
      (e) =>
          e.key.startsWith('${prefix}moment_seen_') &&
          !e.key.startsWith('${prefix}moment_seen_expiry_'),
    )) {
      if (await local.prefs.getString('active_owner') != uid) break;
      final eventId = entry.key.substring('${prefix}moment_seen_'.length);
      final expiryKey = '${prefix}moment_seen_expiry_$eventId',
          expiry = all['${prefix}moment_seen_expiry_$eventId'];
      if (expiry is int && expiry <= stamp) {
        await local.prefs.remove(entry.key);
        await local.prefs.remove(expiryKey);
        removed++;
      } else if (expiry is! int) {
        // Migrate legacy boolean markers without immediately replaying their alerts.
        await local.prefs.setInt(
          expiryKey,
          now().add(const Duration(days: 1)).millisecondsSinceEpoch,
        );
        if (await local.prefs.getString('active_owner') != uid) {
          await local.prefs.remove(expiryKey);
        }
      }
    }
    if (cancelNotice == null) return removed;
    for (final entry in all.entries.where(
      (e) => e.key.startsWith('${prefix}moment_notice_'),
    )) {
      if (await local.prefs.getString('active_owner') != uid) break;
      try {
        final value = jsonDecode(entry.value as String) as Map<String, dynamic>;
        final expiry = value['expiresAt'], id = value['id'];
        if (id is! int || id & 0x40000000 == 0) continue;
        if (expiry is int && expiry <= stamp) {
          await cancelNotice(id);
          await local.prefs.remove(entry.key);
          removed++;
        } else if (expiry is! int) {
          await local.prefs.setString(
            entry.key,
            jsonEncode({
              ...value,
              'expiresAt': now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch,
            }),
          );
          if (await local.prefs.getString('active_owner') != uid) {
            await local.prefs.remove(entry.key);
          }
        }
      } on FormatException {
        await local.prefs.remove(entry.key);
      } on TypeError {
        await local.prefs.remove(entry.key);
      }
    }
    return removed;
  }
}
