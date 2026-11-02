import 'package:flutter/foundation.dart';

typedef Json = Map<String, dynamic>;

class DataFailure implements Exception {
  const DataFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String normalizedName(String name) => name.trim().toLowerCase();
void validateHobby(String name, String description, String? priority) {
  final n = name.trim();
  if (n.runes.length < 2 ||
      n.runes.length > 50 ||
      n.contains('/') ||
      n == '.' ||
      n == '..') {
    throw const DataFailure('Tên cần 2–50 ký tự và không chứa dấu /.');
  }
  if (description.runes.length > 180) {
    throw const DataFailure('Mô tả tối đa 180 ký tự.');
  }
  if (!['active', 'interested'].contains(priority)) {
    throw const DataFailure('Hãy chọn Active hoặc Interested.');
  }
}

@immutable
class Hobby {
  const Hobby({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.priority,
    this.archived = false,
  });
  final String id, name, description, icon, color, priority;
  final bool archived;
  String get nameKey => normalizedName(name);
  factory Hobby.fromJson(String id, Json j) => Hobby(
    id: id,
    name: j['name'] as String,
    description: j['description'] as String,
    icon: j['icon'] as String,
    color: j['color'] as String,
    priority: j['priority'] as String,
    archived: j['archived'] as bool? ?? false,
  );
  Json toJson() => {
    'name': name.trim(),
    'nameKey': nameKey,
    'description': description.trim(),
    'icon': icon,
    'color': color,
    'priority': priority,
    'archived': archived,
  };
  Hobby withPriority(String value) => Hobby(
    id: id,
    name: name,
    description: description,
    icon: icon,
    color: color,
    priority: value,
    archived: archived,
  );
}

@immutable
class PracticePlan {
  const PracticePlan({
    required this.id,
    required this.hobbyId,
    required this.title,
    required this.startsAt,
    required this.minutes,
    this.done = false,
    this.eventId = '',
    this.completionId = '',
  });
  final String id, hobbyId, title, eventId, completionId;
  final DateTime startsAt;
  final int minutes;
  final bool done;
  Json toJson() => {
    'hobbyId': hobbyId,
    'title': title,
    'startsAt': startsAt.toUtc(),
    'minutes': minutes,
    'done': done,
    'eventId': eventId,
    'completionId': completionId,
  };
}

@immutable
class PracticeRecord {
  const PracticeRecord({
    required this.id,
    required this.hobbyId,
    required this.name,
    required this.icon,
    required this.color,
    required this.elapsedMs,
    required this.notes,
    required this.finishedAt,
    this.planId = '',
  });
  final String id, hobbyId, name, icon, color, notes, planId;
  final int elapsedMs;
  final DateTime finishedAt;
  Json toJson() => {
    'hobbyId': hobbyId,
    'name': name,
    'icon': icon,
    'color': color,
    'elapsedMs': elapsedMs,
    'notes': notes,
    'finishedAt': finishedAt.toUtc(),
    'planId': planId,
  };
}

@immutable
class SocialEntry {
  const SocialEntry({required this.id, required this.data});
  final String id;
  final Json data;
  String text(String key) => data[key] as String? ?? '';
  bool flag(String key) => data[key] == true;
  List<String> strings(String key) =>
      List<String>.from(data[key] as List? ?? const []);
  DateTime? date(String key) =>
      data[key] is DateTime ? data[key] as DateTime : null;
}

@immutable
class AppPreferences {
  const AppPreferences({
    this.theme = 'Light',
    this.displayName = '',
    this.handle = '',
    this.bio = '',
    this.color = 'mint',
    this.music = 'youtube',
    this.search = 'google',
    this.reminders = true,
    this.leadMinutes = 15,
    this.messages = true,
    this.groups = true,
    this.weekly = false,
    this.autoTimer = false,
    this.pauseOnExit = true,
    this.sound = false,
    this.visible = false,
    this.allowMessages = false,
  });
  final String theme, displayName, handle, bio, color, music, search;
  final bool reminders,
      messages,
      groups,
      weekly,
      autoTimer,
      pauseOnExit,
      sound,
      visible,
      allowMessages;
  final int leadMinutes;
  Json toJson() => {
    'theme': theme,
    'displayName': displayName,
    'handle': handle,
    'bio': bio,
    'color': color,
    'music': music,
    'search': search,
    'reminders': reminders,
    'leadMinutes': leadMinutes,
    'messages': messages,
    'groups': groups,
    'weekly': weekly,
    'autoTimer': autoTimer,
    'pauseOnExit': pauseOnExit,
    'sound': sound,
    'visible': visible,
    'allowMessages': allowMessages,
  };
  factory AppPreferences.fromJson(Json j) => AppPreferences(
    theme: j['theme'] as String? ?? 'Light',
    displayName: j['displayName'] as String? ?? '',
    handle: j['handle'] as String? ?? '',
    bio: j['bio'] as String? ?? '',
    color: j['color'] as String? ?? 'mint',
    music: j['music'] as String? ?? 'youtube',
    search: j['search'] as String? ?? 'google',
    reminders: j['reminders'] as bool? ?? true,
    leadMinutes: j['leadMinutes'] as int? ?? 15,
    messages: j['messages'] as bool? ?? true,
    groups: j['groups'] as bool? ?? true,
    weekly: j['weekly'] as bool? ?? false,
    autoTimer: j['autoTimer'] as bool? ?? false,
    pauseOnExit: j['pauseOnExit'] as bool? ?? true,
    sound: j['sound'] as bool? ?? false,
    visible: j['visible'] as bool? ?? false,
    allowMessages: j['allowMessages'] as bool? ?? false,
  );
  AppPreferences update(Json values) =>
      AppPreferences.fromJson({...toJson(), ...values});
}

@immutable
class RuntimeFlags {
  const RuntimeFlags({this.community = true, this.feedLimit = 25, this.error});
  final bool community;
  final int feedLimit;
  final String? error;
}

@immutable
class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.path,
    required this.receivedAt,
    this.read = false,
  });
  final String id, title, body, path;
  final DateTime receivedAt;
  final bool read;
  Json toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'path': path,
    'receivedAt': receivedAt.toIso8601String(),
    'read': read,
  };
  factory InboxItem.fromJson(Json j) => InboxItem(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    path: j['path'] as String,
    receivedAt: DateTime.parse(j['receivedAt'] as String),
    read: j['read'] as bool? ?? false,
  );
}
