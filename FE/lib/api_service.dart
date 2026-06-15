// lib/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ─── Base URL (에뮬레이터/시뮬레이터/실기기 자동 감지) ───────────────────
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000'; // Android 에뮬레이터 특수 루프백
    }
    return 'http://localhost:3000'; // 웹 / iOS 시뮬레이터
  }

  // ─── 토큰 저장 / 불러오기 ───────────────────────────────────────────────
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
  }

  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user['id']?.toString() ?? '');
    await prefs.setString('studentId', user['studentId']?.toString() ?? '');
    await prefs.setString('userName', user['name']?.toString() ?? '');
  }

  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('userId') ?? '',
      'studentId': prefs.getString('studentId') ?? '',
      'name': prefs.getString('userName') ?? '',
    };
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('studentId');
    await prefs.remove('userName');
  }

  // ─── 공통 헤더 ──────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── 토큰 자동 갱신 ────────────────────────────────────────────────────
  static Future<bool> _tryRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final url = Uri.parse('$baseUrl/auth/refresh');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── GET 헬퍼 (401 → 토큰 갱신 후 재시도) ──────────────────────────────
  static Future<http.Response> _get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    var res = await http.get(url, headers: await _authHeaders());
    if (res.statusCode == 401) {
      if (await _tryRefresh()) {
        res = await http.get(url, headers: await _authHeaders());
      }
    }
    return res;
  }

  // ─── POST 헬퍼 ─────────────────────────────────────────────────────────
  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    var res = await http.post(url, headers: await _authHeaders(), body: jsonEncode(body));
    if (res.statusCode == 401) {
      if (await _tryRefresh()) {
        res = await http.post(url, headers: await _authHeaders(), body: jsonEncode(body));
      }
    }
    return res;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 인증 (Auth)
  // ═══════════════════════════════════════════════════════════════════════

  /// Google idToken → BE 검증 → JWT 저장
  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      await saveUserInfo(data['user'] as Map<String, dynamic>);
      return data;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '로그인에 실패했습니다.');
  }

  /// 학번/비밀번호 → 포털 인증 → JWT 저장
  static Future<Map<String, dynamic>> loginWithEmail(
      String studentId, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'studentId': studentId, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      await saveUserInfo(data['user'] as Map<String, dynamic>);
      return data;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '로그인에 실패했습니다.');
  }

  /// 회원가입 OTP 전송
  static Future<void> sendOtp({
    required String name,
    required String studentId,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/send-otp');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'studentId': studentId, 'password': password}),
    );
    if (res.statusCode == 200) return;
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '인증번호 전송에 실패했습니다.');
  }

  /// OTP 검증 및 계정 생성 → JWT 저장
  static Future<Map<String, dynamic>> verifyOtp({
    required String studentId,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register/verify-otp');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'studentId': studentId, 'otp': otp}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      await saveUserInfo(data['user'] as Map<String, dynamic>);
      return data;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '인증에 실패했습니다.');
  }

  /// PATCH /auth/password → 비밀번호 변경
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _post('/auth/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    if (res.statusCode == 200) return;
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '비밀번호 변경에 실패했습니다.');
  }

  static Future<void> logout() async {
    try {
      await _post('/auth/logout', {});
    } catch (_) {}
    await clearAll();
  }

  static Future<void> deleteAccount() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final headers = await _authHeaders();
    await http.delete(url, headers: headers);
    await clearAll();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 식당 (Restaurants)
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /restaurants → 전체 식당 목록
  static Future<List<dynamic>> getRestaurants() async {
    final res = await _get('/restaurants');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('식당 목록을 불러오지 못했습니다. (${res.statusCode})');
  }

  /// GET /restaurants/:id/menus → 특정 식당의 활성 메뉴 목록
  static Future<List<dynamic>> getRestaurantMenus(String restaurantId) async {
    final res = await _get('/restaurants/$restaurantId/menus');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('메뉴를 불러오지 못했습니다. (${res.statusCode})');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 주문 (Orders)
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /orders/me → 내 주문 내역 (최근 10건)
  static Future<List<dynamic>> getMyOrders() async {
    final res = await _get('/orders/me');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('주문 내역을 불러오지 못했습니다. (${res.statusCode})');
  }

  /// POST /orders/validate → 장바구니 검증 + idempotencyKey 발급
  static Future<Map<String, dynamic>> validateOrder(
      List<Map<String, dynamic>> items) async {
    final res = await _post('/orders/validate', {'items': items});
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '주문 검증에 실패했습니다.');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AI 추천 (Recommendations)
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /recommendations/preference → 주문 이력 기반 추천
  static Future<List<dynamic>> getPreferenceRecommendations() async {
    final res = await _get('/recommendations/preference');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('맞춤 추천을 불러오지 못했습니다. (${res.statusCode})');
  }

  /// GET /recommendations/weather → 날씨 기반 추천
  static Future<List<dynamic>> getWeatherRecommendations() async {
    final res = await _get('/recommendations/weather');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('날씨 추천을 불러오지 못했습니다. (${res.statusCode})');
  }

  /// GET /recommendations/popular → 오늘 인기 메뉴 (1등 랭킹)
  static Future<List<dynamic>> getPopularRecommendations() async {
    final res = await _get('/recommendations/popular');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('인기 추천을 불러오지 못했습니다. (${res.statusCode})');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 주문 (Quick Order) — FE 직접 연동용
  // ═══════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> submitPreOrder(Map<String, dynamic> orderDetails) async {
    final res = await ApiService._post('/orders/quick', orderDetails);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '주문 전송에 실패했습니다. (${res.statusCode})');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 식권 (Tickets)
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /tickets → 내 식권 목록
  static Future<List<dynamic>> getTickets() async {
    final res = await _get('/tickets');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('식권 목록을 불러오지 못했습니다. (${res.statusCode})');
  }

  /// POST /tickets → 식권 번호 등록
  static Future<Map<String, dynamic>> registerTicket(String ticketNumber) async {
    final res = await _post('/tickets', {'ticketNumber': ticketNumber});
    if (res.statusCode == 201) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '식권 등록에 실패했습니다.');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 리뷰 (Reviews)
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /menus/me/reviews → 내가 쓴 리뷰 목록
  static Future<List<dynamic>> getMyReviews() async {
    final res = await _get('/menus/me/reviews');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    }
    throw Exception('리뷰를 불러오지 못했습니다. (${res.statusCode})');
  }

  /// GET /menus/:menuId/reviews → 특정 메뉴 리뷰
  static Future<Map<String, dynamic>> getMenuReviews(String menuId) async {
    final res = await _get('/menus/$menuId/reviews');
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('리뷰를 불러오지 못했습니다. (${res.statusCode})');
  }

  /// POST /menus/:menuId/reviews → 리뷰 작성
  static Future<void> submitReview(String menuId, int rating, String comment) async {
    final res = await _post('/menus/$menuId/reviews', {'rating': rating, 'comment': comment});
    if (res.statusCode == 200 || res.statusCode == 201) return;
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '리뷰 작성에 실패했습니다.');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 문의 (Inquiry)
  // ═══════════════════════════════════════════════════════════════════════

  /// POST /inquiry → 문의 접수
  static Future<void> submitInquiry(String content) async {
    final res = await _post('/inquiry', {'content': content});
    if (res.statusCode == 200 || res.statusCode == 201) return;
    final err = jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception(err['message'] ?? '문의 접수에 실패했습니다.');
  }
}
