import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'order_channel';
  static const _prefKey = 'hasUnreadNotification';

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  static Future<void> showOrderAccepted({
    required String restaurantName,
    required String itemName,
    required int quantity,
    required int totalAmount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      '주문 알림',
      channelDescription: '주문 접수 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '주문이 접수되었습니다',
      '$restaurantName · $itemName $quantity개',
      const NotificationDetails(android: androidDetails),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  static Future<bool> hasUnread() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> clearUnread() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
