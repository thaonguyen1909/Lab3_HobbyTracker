import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hobby_data.dart';

class LocalOwnerStore {
  LocalOwnerStore({SharedPreferencesAsync? preferences})
    : prefs = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync prefs;
  String prefix(String uid) => 'owner_${base64Url.encode(utf8.encode(uid))}_';
  Future<void> setOwner(String? uid) async {
    if (uid == null) {
      await prefs.remove('active_owner');
    } else {
      await prefs.setString('active_owner', uid);
    }
  }

  Future<void> clearOwner(String uid) async {
    final keys = await prefs.getKeys();
    for (final key in keys.where((k) => k.startsWith(prefix(uid)))) {
      await prefs.remove(key);
    }
    if (await prefs.getString('active_owner') == uid) {
      await prefs.remove('active_owner');
    }
  }

  Future<void> saveNotification(String uid, InboxItem item) async {
    final key = '${prefix(uid)}notification_${item.id}';
    if (await prefs.getString('active_owner') != uid) return;
    await prefs.setString(key, jsonEncode(item.toJson()));
    if (await prefs.getString('active_owner') != uid) await prefs.remove(key);
  }

  Future<List<InboxItem>> notifications(String uid) async {
    final keys = await prefs.getKeys();
    final result = <InboxItem>[];
    for (final key in keys.where(
      (k) =>
          k.startsWith('${prefix(uid)}notification_') &&
          k != '${prefix(uid)}notification_preferences',
    )) {
      try {
        final value = await prefs.getString(key);
        if (value != null) {
          result.add(InboxItem.fromJson(jsonDecode(value) as Json));
        }
      } on FormatException {
        await prefs.remove(key);
      } on TypeError {
        await prefs.remove(key);
      }
    }
    result.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    return result;
  }

  Future<Json?> readDraft(String uid) async {
    final value = await prefs.getString('${prefix(uid)}hyper_draft');
    if (value == null) return null;
    try {
      return jsonDecode(value) as Json;
    } on FormatException {
      await prefs.remove('${prefix(uid)}hyper_draft');
      return null;
    }
  }

  Future<void> writeDraft(String uid, Json? draft) async {
    final key = '${prefix(uid)}hyper_draft';
    if (draft == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(draft));
    }
  }
}
