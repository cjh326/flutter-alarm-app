import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:html' as html if (dart.library.io) 'dart:io';
import 'package:just_audio/just_audio.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void alarmCallback(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final alarms = prefs.getStringList('alarms') ?? [];
  final index = alarms.indexWhere((alarm) => int.parse(alarm.split('|')[1]) == id);
  
  if (index != -1) {
    final parts = alarms[index].split('|')[0].split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    // 显示通知
    await flutterLocalNotificationsPlugin.show(
      0,
      '闹钟提醒',
      '现在是 $hour:$minute',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          '闹钟提醒',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    
    // 删除闹钟
    alarms.removeAt(index);
    await prefs.setStringList('alarms', alarms);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    await AndroidAlarmManager.initialize();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  
  runApp(const AlarmApp());
}

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '闹钟应用',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AlarmScreen(),
    );
  }
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<String> alarms = [];
  Timer? _timer;
  dynamic _audio;  // Web版本使用AudioElement，Android版本不使用
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showAlert(TimeOfDay time) async {
    if (!mounted) return;

    if (kIsWeb) {
      // Web版本使用AudioElement
      _audio = html.AudioElement()
        ..src = 'beep.mp3'
        ..loop = true
        ..play();
    } else {
      // Android版本使用通知和音频
      final player = AudioPlayer();
      await player.setAsset('assets/alarm_sound.mp3');
      await player.play();
      
      await flutterLocalNotificationsPlugin.show(
        0,
        '闹钟提醒',
        '现在是 ${time.hour}:${time.minute}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel',
            '闹钟提醒',
            importance: Importance.max,
            priority: Priority.high,
            playSound: false,  // 禁用系统声音，使用自定义音乐
          ),
        ),
      );
      
      _audio = player;  // 保存player引用以便后续停止
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('闹钟提醒'),
        content: Text('现在是 ${time.hour}:${time.minute}'),
        actions: [
          TextButton(
            onPressed: () {
              if (kIsWeb) {
                final webAudio = _audio as html.AudioElement;
                webAudio.pause();
                webAudio.remove();
                _audio = null;
              } else {
                final player = _audio as AudioPlayer;
                player.stop();
                player.dispose();
                _audio = null;
              }
              Navigator.pop(context);
            },
            child: const Text('停止闹钟'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeAlarm(int id) async {
    setState(() {
      alarms.removeWhere((alarm) => int.parse(alarm.split('|')[1]) == id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('alarms', alarms);
  }

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      alarms = prefs.getStringList('alarms') ?? [];
    });
  }

  Future<void> _addAlarm(TimeOfDay time) async {
    final now = DateTime.now();
    var alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final id = alarmTime.millisecondsSinceEpoch;
    final alarmString = '${time.hour}:${time.minute}|$id';
    
    setState(() {
      alarms.add(alarmString);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('alarms', alarms);
    
    if (kIsWeb) {
      // Web版本使用Timer
      _timer?.cancel();
      _timer = Timer(alarmTime.difference(now), () {
        _showAlert(time);
        _removeAlarm(id);
      });
    } else {
      // Android版本使用AndroidAlarmManager
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        id,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        startAt: alarmTime,
      );
    }
  }

  Future<void> _addBatchAlarms() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量添加闹钟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '间隔分钟数'),
              keyboardType: TextInputType.number,
              onChanged: (value) => intervalMinutes = int.tryParse(value) ?? 30,
            ),
            TextField(
              decoration: const InputDecoration(labelText: '闹钟数量'),
              keyboardType: TextInputType.number,
              onChanged: (value) => count = int.tryParse(value) ?? 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'intervalMinutes': intervalMinutes,
              'count': count,
            }),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null) {
      var currentTime = startTime;
      for (var i = 0; i < result['count']; i++) {
        await _addAlarm(currentTime);
        final nextMinutes = currentTime.hour * 60 + currentTime.minute + result['intervalMinutes'];
        currentTime = TimeOfDay(
          hour: (nextMinutes ~/ 60) % 24,
          minute: (nextMinutes % 60).toInt(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闹钟应用'),
      ),
      body: ListView.builder(
        itemCount: alarms.length,
        itemBuilder: (context, index) {
          final parts = alarms[index].split('|');
          final timeStr = parts[0];
          return ListTile(
            title: Text('闹钟时间: $timeStr'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final id = int.parse(parts[1]);
                _removeAlarm(id);
              },
            ),
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _addBatchAlarms,
            tooltip: '批量添加闹钟',
            child: const Icon(Icons.alarm_add),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                await _addAlarm(time);
              }
            },
            tooltip: '添加闹钟',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

int intervalMinutes = 30;
int count = 3;
