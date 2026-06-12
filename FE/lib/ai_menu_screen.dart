// lib/ai_menu_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'cart_screen.dart';

class AiMenuScreen extends StatefulWidget {
  const AiMenuScreen({Key? key}) : super(key: key);

  @override
  State<AiMenuScreen> createState() => _AiMenuScreenState();
}

class _AiMenuScreenState extends State<AiMenuScreen> {
  late Future<_RecommendData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAll();
  }

  Future<_RecommendData> _loadAll() async {
    final results = await Future.wait([
      ApiService.getRestaurants(),
      ApiService.getPreferenceRecommendations().catchError((_) => <dynamic>[]),
      ApiService.getWeatherRecommendations().catchError((_) => <dynamic>[]),
      ApiService.getPopularRecommendations().catchError((_) => <dynamic>[]),
    ]);

    final restaurants = results[0];
    final restaurantMap = {
      for (final r in restaurants) r['id'] as String: r['name'] as String
    };

    return _RecommendData(
      preference: results[1],
      weather: results[2],
      popular: results[3],
      restaurantMap: restaurantMap,
    );
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('AI 스마트 메뉴 추천',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textDark, size: 20),
            onPressed: () => setState(() => _dataFuture = _loadAll()),
          ),
        ],
      ),
      body: FutureBuilder<_RecommendData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI가 추천 메뉴를 분석 중입니다...',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _dataFuture = _loadAll()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final prefList = data.preference;
          final weatherList = data.weather;
          final popularList = data.popular;
          final restMap = data.restaurantMap;

          final hero = prefList.isNotEmpty
              ? prefList.first as Map<String, dynamic>
              : null;
          final sub1 = weatherList.isNotEmpty
              ? weatherList.first as Map<String, dynamic>
              : null;
          final sub2 = weatherList.length > 1
              ? weatherList[1] as Map<String, dynamic>
              : (prefList.length > 1 ? prefList[1] as Map<String, dynamic> : null);
          final ranking = popularList.isNotEmpty
              ? popularList.first as Map<String, dynamic>
              : null;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    _buildHeroCard(context, hero, restMap),
                    if (sub1 != null || sub2 != null)
                      _buildSubCardsRow(context, sub1, sub2, restMap),
                    if (ranking != null)
                      _buildRankingCard(context, ranking, restMap),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (hero != null)
                _buildBottomStrip(context, hero),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 상단 헤더 텍스트
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('오늘은\n이런 메뉴 어떠세요?',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  height: 1.3)),
          SizedBox(height: 6),
          Text('주문 기록과 날씨를 분석해 추천해드려요.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 히어로 카드 (내 취향 분석 AI 픽) — 진한 파란 배경
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeroCard(
    BuildContext context,
    Map<String, dynamic>? hero,
    Map<String, String> restMap,
  ) {
    if (hero == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '주문 내역이 쌓이면\n맞춤 추천이 제공됩니다.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
        ),
      );
    }

    final name = hero['name'] as String;
    final price = hero['price'] as int;
    final restaurantName =
        restMap[hero['restaurantId'] as String? ?? ''] ?? '';
    final reason = hero['reason'] as String? ??
        '최근 주문 기록을 분석한 맞춤 추천 메뉴입니다.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded,
                    color: Colors.white70, size: 15),
                SizedBox(width: 6),
                Text('내 취향 분석 AI 픽',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${_formatPrice(price)}원 • $restaurantName',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('"$reason"',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Colors.white, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    menuName: name,
                    priceString: '${_formatPrice(price)}원',
                  ),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('담기',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 서브 카드 2열
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSubCardsRow(
    BuildContext context,
    Map<String, dynamic>? sub1,
    Map<String, dynamic>? sub2,
    Map<String, String> restMap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sub1 != null)
            Expanded(
              child: _buildSubCard(
                context: context,
                menu: sub1,
                badgeLabel: '날씨 기반 AI 픽',
                icon: Icons.wb_sunny_rounded,
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFF97316),
                description: sub1['reason'] as String? ??
                    '오늘 날씨에 딱 맞는 추천 메뉴입니다.',
              ),
            ),
          if (sub1 != null && sub2 != null) const SizedBox(width: 12),
          if (sub2 != null)
            Expanded(
              child: _buildSubCard(
                context: context,
                menu: sub2,
                badgeLabel: '가장 빠른 수령',
                icon: Icons.timer_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF22C55E),
                description: sub2['reason'] as String? ??
                    '주문 후 조리시간이 가장 빨라요!',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubCard({
    required BuildContext context,
    required Map<String, dynamic> menu,
    required String badgeLabel,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String description,
  }) {
    final name = menu['name'] as String;
    final price = menu['price'] as int;
    final priceStr = '${_formatPrice(price)}원';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(badgeLabel,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(priceStr,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight, height: 1.4)),
          const SizedBox(height: 14),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              backgroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CartScreen(menuName: name, priceString: priceStr),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, size: 14, color: AppColors.textLight),
                SizedBox(width: 4),
                Text('담기',
                    style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 오늘의 1등 랭킹 카드
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildRankingCard(
    BuildContext context,
    Map<String, dynamic> ranking,
    Map<String, String> restMap,
  ) {
    final name = ranking['name'] as String;
    final price = ranking['price'] as int;
    final priceStr = '${_formatPrice(price)}원';
    final count = ranking['orderCount'] ?? ranking['todayOrderCount'];
    final countText = count != null ? '($count명 주문)' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오늘의 1등 랭킹',
                      style: TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text(
                    '오늘 단국대 학우들이 가장 많이 찾은 베스트셀러! $countText',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CartScreen(menuName: name, priceString: priceStr),
                ),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child:
                    const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // 하단 고정 장바구니 바
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBottomStrip(BuildContext context, Map<String, dynamic> hero) {
    final name = hero['name'] as String;
    final price = hero['price'] as int;
    final priceStr = '${_formatPrice(price)}원';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding:
            const EdgeInsets.only(left: 20, right: 20, bottom: 28, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CartScreen(menuName: name, priceString: priceStr),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('1',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('장바구니 보기',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const Spacer(),
                Text(priceStr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendData {
  final List<dynamic> preference;
  final List<dynamic> weather;
  final List<dynamic> popular;
  final Map<String, String> restaurantMap;

  _RecommendData({
    required this.preference,
    required this.weather,
    required this.popular,
    required this.restaurantMap,
  });
}
