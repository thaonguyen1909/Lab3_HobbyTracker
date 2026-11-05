/// Design traceability: S01–S15 routes, plus 6 Settings variants.
abstract final class RoutePaths {
  static const authLoading = '/auth/loading';
  static const authFailure = '/auth/error';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const home = '/home';
  static const hyper = '/home/hyper';
  static const hobbies = '/hobbies';
  static String hobbyDetail(String id) => '/hobbies/${Uri.encodeComponent(id)}';
  static const feed = '/community/feed';
  static const moments = '/community/moments';
  static const momentAlerts = '/community/moments/alerts';
  static String momentsForGroup(String groupId) =>
      '$moments?group=${Uri.encodeQueryComponent(groupId)}';
  static String createMoment(String groupId) =>
      '$moments/create?group=${Uri.encodeQueryComponent(groupId)}';
  static String groupMoment(String groupId, String momentId) =>
      '/community/groups/${Uri.encodeComponent(groupId)}/moments/${Uri.encodeComponent(momentId)}';
  static const groups = '/community/groups';
  static const activities = '/community/activities';
  static const people = '/community/people';
  static const chats = '/community/chats';
  static String conversation(String id) =>
      '/community/chat/${Uri.encodeComponent(id)}';
  static const settings = '/settings';
  static String settingsDetail(String section) =>
      '/settings/${Uri.encodeComponent(section)}';

  static const settingsSections = <String, String>{
    'profile': 'Profile & Account',
    'language': 'Language',
    'apps': 'Connected Apps',
    'notifications': 'Notifications',
    'hyper': 'Hyper Preferences',
    'privacy': 'Privacy & Safety',
    'appearance': 'Appearance',
  };
}
