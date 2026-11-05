import 'hobby_data.dart';

enum ScheduleRepeat { none, daily, weekly }

const maxScheduleMinutes = 1440;
const maxScheduleOccurrences = 100;

void validatePracticePlan(PracticePlan plan) {
  if (plan.title.trim().isEmpty ||
      plan.title.trim().runes.length > 70 ||
      plan.minutes < 1 ||
      plan.minutes > maxScheduleMinutes) {
    throw const DataFailure(
      'Enter a session name and a duration from 1 to 1440 minutes.',
    );
  }
}

/// Calendar-day arithmetic keeps the chosen local wall time across DST changes.
List<DateTime> scheduleOccurrences(
  DateTime start,
  ScheduleRepeat repeat,
  DateTime? until,
) {
  if (repeat == ScheduleRepeat.none) return [start];
  if (until == null ||
      DateTime(
        until.year,
        until.month,
        until.day,
      ).isBefore(DateTime(start.year, start.month, start.day))) {
    throw const DataFailure('Choose an end date on or after the session date.');
  }
  final result = <DateTime>[];
  final last = DateTime(until.year, until.month, until.day);
  final step = repeat == ScheduleRepeat.daily ? 1 : 7;
  for (var offset = 0; ; offset += step) {
    final date = start.isUtc
        ? DateTime.utc(
            start.year,
            start.month,
            start.day + offset,
            start.hour,
            start.minute,
          )
        : DateTime(
            start.year,
            start.month,
            start.day + offset,
            start.hour,
            start.minute,
          );
    if (DateTime(date.year, date.month, date.day).isAfter(last)) break;
    result.add(date);
    if (result.length > maxScheduleOccurrences) {
      throw const DataFailure(
        'Choose a shorter repeat range (maximum 100 sessions).',
      );
    }
  }
  return result;
}

bool sameScheduleContent(PracticePlan a, PracticePlan b) =>
    a.hobbyId == b.hobbyId &&
    a.title.trim() == b.title.trim() &&
    a.startsAt.isAtSameMomentAs(b.startsAt) &&
    a.minutes == b.minutes &&
    a.eventId == b.eventId;
