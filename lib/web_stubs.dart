import 'dart:async';
import 'dart:html' as html;

// Web平台的存根实现
typedef AlarmCallback = void Function(int id);
class AndroidAlarmManager {
  static Timer? _timer;
  static const _checkInterval = Duration(seconds: 30);
  static AlarmCallback? _callback;

  static Future<bool> initialize() async {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, _checkAlarms);
    return true;
  }

  static void _checkAlarms(Timer timer) {
    final now = DateTime.now();
    final storage = html.window.localStorage;
    final alarmKeys = storage.keys.where((key) => key.startsWith('alarm_'));

    for (final key in alarmKeys) {
      final value = storage[key];
      if (value != null) {
        final parts = value.split('|');
        if (parts.length == 2) {
          final timeStr = parts[0];
          final id = parts[1];
          final timeParts = timeStr.split(':');
          if (timeParts.length == 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            var alarmTime = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            if (alarmTime.isBefore(now)) {
              alarmTime = alarmTime.add(const Duration(days: 1));
            }

            if (now.difference(alarmTime).inMinutes >= 0 &&
                now.difference(alarmTime).inMinutes < 1) {
              storage.remove(key);
              _callback?.call(int.parse(id));
            }
          }
        }
      }
    }
  }

  static Future<bool> oneDayAt(
    int id,
    int hour,
    int minute,
    AlarmCallback callback, {
    bool exact = false,
    bool wakeup = false,
    bool rescheduleOnReboot = false,
  }) async {
    _callback = callback;
    final timeStr = '$hour:$minute';
    html.window.localStorage['alarm_$id'] = '$timeStr|$id';
    return true;
  }

  static Future<bool> cancel(int id) async {
    html.window.localStorage.remove('alarm_$id');
    return true;
  }
}

enum Importance {
  unspecified,
  none,
  min,
  low,
  defaultImportance,
  high,
  max
}

enum Priority {
  min,
  low,
  defaultPriority,
  high,
  max
}

class AndroidInitializationSettings {
  const AndroidInitializationSettings(this.defaultIcon);
  final String defaultIcon;
}

class InitializationSettings {
  const InitializationSettings({this.android});
  final AndroidInitializationSettings? android;
}

class AndroidNotificationDetails {
  const AndroidNotificationDetails(
    this.channelId,
    this.channelName, {
    this.importance = Importance.defaultImportance,
    this.priority = Priority.defaultPriority,
  });

  final String channelId;
  final String channelName;
  final Importance importance;
  final Priority priority;
}

class NotificationDetails {
  const NotificationDetails({this.android});
  final AndroidNotificationDetails? android;
}

class FlutterLocalNotificationsPlugin {
  Future<void> initialize(InitializationSettings settings) async {}
  Future<void> show(
    int id,
    String title,
    String body,
    NotificationDetails? details,
  ) async {}
}

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
