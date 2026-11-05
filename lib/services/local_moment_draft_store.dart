import 'dart:convert';
import '../models/group_moment.dart';
import 'moment_repository.dart';
import 'local_owner_store.dart';

class LocalMomentDraftStore implements MomentDraftStore {
  LocalMomentDraftStore(this.local);
  final LocalOwnerStore local;
  String _key(String uid, String groupId) =>
      '${local.prefix(uid)}moment_draft_${base64Url.encode(utf8.encode(groupId))}';
  @override
  Future<MomentDraft?> read(String uid, String groupId) async {
    if (await local.prefs.getString('active_owner') != uid) return null;
    final raw = await local.prefs.getString(_key(uid, groupId));
    if (raw == null) return null;
    try {
      final value = momentMap(jsonDecode(raw));
      return MomentDraft(
        groupId: momentString(value, 'groupId'),
        hobbyId: momentString(value, 'hobbyId'),
        caption: momentString(value, 'caption'),
        requestId: momentString(value, 'requestId'),
        picking: value['picking'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(String uid, MomentDraft draft) async {
    if (await local.prefs.getString('active_owner') != uid) return;
    final key = _key(uid, draft.groupId);
    await local.prefs.setString(key, jsonEncode(draft.toJson()));
    if (await local.prefs.getString('active_owner') != uid) {
      await local.prefs.remove(key);
    }
  }

  @override
  Future<void> clear(String uid, String groupId) =>
      local.prefs.remove(_key(uid, groupId));
}
