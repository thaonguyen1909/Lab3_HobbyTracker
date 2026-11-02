import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hobby_data.dart';
import '../services/app_services.dart';
import 'auth_view_model.dart';

final ownerIdProvider = Provider<String?>(
  (ref) => ref.watch(authIdentityProvider).valueOrNull?.uid,
);
final hobbiesProvider = StreamProvider.autoDispose<List<Hobby>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).hobbies(uid);
});
final plansProvider = StreamProvider.autoDispose<List<PracticePlan>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).plans(uid);
});
final historyProvider = StreamProvider.autoDispose<List<PracticeRecord>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).history(uid);
});
final preferencesProvider = StreamProvider<AppPreferences>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value(const AppPreferences())
      : ref.watch(repositoryProvider).preferences(uid);
});
final flagsProvider = FutureProvider<RuntimeFlags>(
  (ref) => ref.watch(deviceServicesProvider).flags(),
);
final diagnosticsProvider = StreamProvider<String>(
  (ref) => ref.watch(deviceServicesProvider).diagnostics,
);
final inboxProvider = StreamProvider.autoDispose<List<InboxItem>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(deviceServicesProvider).inbox(uid);
});
final feedProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  ref.watch(ownerIdProvider);
  final flags = ref.watch(flagsProvider).valueOrNull ?? const RuntimeFlags();
  return ref.watch(repositoryProvider).feed(flags.feedLimit);
});
final groupsProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  ref.watch(ownerIdProvider);
  return ref.watch(repositoryProvider).groups();
});
final joinedGroupsProvider = StreamProvider.autoDispose<List<SocialEntry>>((
  ref,
) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).joinedGroups(uid);
});
final eventsProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  ref.watch(ownerIdProvider);
  return ref.watch(repositoryProvider).events();
});
final rsvpsProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).rsvps(uid);
});
final peopleProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  ref.watch(ownerIdProvider);
  return ref.watch(repositoryProvider).people();
});
final chatsProvider = StreamProvider.autoDispose<List<SocialEntry>>((ref) {
  final uid = ref.watch(ownerIdProvider);
  return uid == null
      ? Stream.value([])
      : ref.watch(repositoryProvider).chats(uid);
});
final commentsProvider = StreamProvider.autoDispose
    .family<List<SocialEntry>, String>((ref, id) {
      ref.watch(ownerIdProvider);
      return ref.watch(repositoryProvider).comments(id);
    });
final likesProvider = StreamProvider.autoDispose
    .family<List<SocialEntry>, String>((ref, id) {
      ref.watch(ownerIdProvider);
      return ref.watch(repositoryProvider).likes(id);
    });
final messagesProvider = StreamProvider.autoDispose
    .family<List<SocialEntry>, ({String id, bool group})>((ref, key) {
      final uid = ref.watch(ownerIdProvider);
      return uid == null
          ? Stream.value([])
          : ref.watch(repositoryProvider).messages(uid, key.id, key.group);
    });

List<PracticePlan> visiblePlans(
  List<PracticePlan> plans,
  List<Hobby> hobbies,
  DateTime day,
) {
  final ids = hobbies.map((h) => h.id).toSet();
  return plans
      .where(
        (p) =>
            ids.contains(p.hobbyId) &&
            p.startsAt.toLocal().year == day.year &&
            p.startsAt.toLocal().month == day.month &&
            p.startsAt.toLocal().day == day.day,
      )
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}

String elapsedLabel(int ms) {
  final d = Duration(milliseconds: ms);
  return '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

List<SocialEntry> rankFeed(
  List<SocialEntry> items,
  List<Hobby> hobbies,
  bool forYou,
) {
  if (!forYou) return List.of(items);
  final scores = {
    for (final h in hobbies)
      normalizedName(h.name): h.priority == 'active' ? 2 : 1,
  };
  final order = {for (var i = 0; i < items.length; i++) items[i].id: i};
  return List<SocialEntry>.of(items)..sort((a, b) {
    final score = (scores[normalizedName(b.text('topic'))] ?? 0).compareTo(
      scores[normalizedName(a.text('topic'))] ?? 0,
    );
    return score == 0 ? order[a.id]!.compareTo(order[b.id]!) : score;
  });
}

List<DateTime> weekDays(DateTime day) {
  final start = DateTime(day.year, day.month, day.day - (day.weekday - 1));
  return List.generate(
    7,
    (i) => DateTime(start.year, start.month, start.day + i),
  );
}
