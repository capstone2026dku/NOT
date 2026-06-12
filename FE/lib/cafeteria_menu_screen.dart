// lib/cafeteria_menu_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'payment_screen.dart';
import 'screens/review_screen.dart';

// ─── 데이터 모델 ────────────────────────────────────────────────────────────

class MenuItem {
  final String id; // BE 메뉴 ID (주문 시 사용)
  final String restaurantId;
  final String name;
  final int price;
  final String corner; // 식당 이름 (표시용)
  final String description;
  final double rating;
  final int reviewCount;
  final bool isSoldout;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.corner,
    this.description = '정성껏 만든 학식 메뉴입니다.',
    this.rating = 4.8,
    this.reviewCount = 4,
    this.isSoldout = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json, {String corner = ''}) {
    return MenuItem(
      id: json['id'] as String,
      restaurantId: json['restaurantId'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      corner: corner,
      isSoldout: json['isSoldout'] as bool? ?? false,
    );
  }
}

class CartItem {
  final MenuItem menu;
  int quantity;
  List<String> selectedOptions;
  int extraCharges;

  CartItem({
    required this.menu,
    this.quantity = 1,
    required this.selectedOptions,
    required this.extraCharges,
  });
}

// ─── 식당 아이콘/색상 로컬 매핑 (BE는 이름만 반환) ─────────────────────────

Map<String, dynamic> _restaurantStyle(String name) {
  const styles = <String, Map<String, dynamic>>{
    '51장국밥': {
      'icon': Icons.soup_kitchen_outlined,
      'color': Color(0xFFFFEFE6),
      'iconColor': Color(0xFFFF6B00)
    },
    '값찌개': {
      'icon': Icons.local_fire_department_outlined,
      'color': Color(0xFFFFF0F0),
      'iconColor': Color(0xFFFF3B30)
    },
    '경성카츠': {
      'icon': Icons.layers_outlined,
      'color': Color(0xFFFFFBEB),
      'iconColor': Color(0xFFD97706)
    },
    '광뚝': {
      'icon': Icons.dinner_dining_outlined,
      'color': Color(0xFFF1F5F9),
      'iconColor': Color(0xFF475569)
    },
    '바비든든': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFE6FBF4),
      'iconColor': Color(0xFF10B981)
    },
    '비비고고': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFE0FAFA),
      'iconColor': Color(0xFF06B6D4)
    },
    '뽀까뽀까': {
      'icon': Icons.restaurant_rounded,
      'color': Color(0xFFE0F2FE),
      'iconColor': Color(0xFF0EA5E9)
    },
    '중식대장': {
      'icon': Icons.outdoor_grill_outlined,
      'color': Color(0xFFFAE8FF),
      'iconColor': Color(0xFFD946EF)
    },
    '폭풍분식': {
      'icon': Icons.fastfood_outlined,
      'color': Color(0xFFFEF08A),
      'iconColor': Color(0xFFCA8A04)
    },
  };
  return styles[name] ??
      {
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFF475569)
      };
}

// ─── 화면 위젯 ─────────────────────────────────────────────────────────────

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({Key? key}) : super(key: key);

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  String? _currentScreen; // null=식당목록, 'menu'=메뉴목록, 'cart'=장바구니
  Map<String, dynamic>? _selectedRestaurant;
  List<CartItem> cartList = [];

  late Future<List<dynamic>> _restaurantsFuture;
  Future<List<MenuItem>>? _menusFuture;

  @override
  void initState() {
    super.initState();
    _restaurantsFuture = ApiService.getRestaurants();
  }

  void _selectRestaurant(Map<String, dynamic> rest) {
    setState(() {
      _selectedRestaurant = rest;
      _currentScreen = 'menu';
      _menusFuture = _fetchMenus(rest['id'] as String, rest['name'] as String);
    });
  }

  Future<List<MenuItem>> _fetchMenus(String restaurantId, String restaurantName) async {
    final raw = await ApiService.getRestaurantMenus(restaurantId);
    return raw
        .map((m) => MenuItem.fromJson(m as Map<String, dynamic>, corner: restaurantName))
        .where((m) => !m.isSoldout) // 품절 메뉴 제외 (원하면 표시 가능)
        .toList();
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  int get _totalCartPrice =>
      cartList.fold(0, (s, i) => s + (i.menu.price + i.extraCharges) * i.quantity);
  int get _totalCartCount => cartList.fold(0, (s, i) => s + i.quantity);

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == 'cart') return _buildCartScreen();
    if (_currentScreen == 'menu' && _selectedRestaurant != null) {
      return _buildMenuScreen(_selectedRestaurant!);
    }
    return _buildRestaurantListScreen();
  }

  // ══════════════════════════════════════════════════════════════════════
  // VIEW 1: 식당 목록
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildRestaurantListScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('학식당',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.search_rounded,
                  color: AppColors.textDark, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _restaurantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _restaurantsFuture = ApiService.getRestaurants()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final restaurants = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Text('입점 식당 목록',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final rest = restaurants[index] as Map<String, dynamic>;
                    final style = _restaurantStyle(rest['name'] as String);
                    final isLocked = rest['isLocked'] as bool? ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: style['color'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(style['icon'] as IconData,
                              color: style['iconColor'] as Color, size: 22),
                        ),
                        title: Text(rest['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark)),
                        subtitle: isLocked
                            ? const Text('현재 주문 불가',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: Color(0xFFCBD5E1)),
                        onTap: isLocked
                            ? null
                            : () => _selectRestaurant({
                                  ...rest,
                                  'icon': style['icon'],
                                  'color': style['color'],
                                  'iconColor': style['iconColor'],
                                }),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // VIEW 2: 메뉴 목록
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildMenuScreen(Map<String, dynamic> restaurant) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => setState(() => _currentScreen = null),
        ),
        title: Text(restaurant['name'] as String,
            style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _menusFuture = _fetchMenus(
                          restaurant['id'] as String,
                          restaurant['name'] as String);
                    }),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('현재 이용 가능한 메뉴가 없습니다.',
                  style: TextStyle(color: AppColors.textLight)),
            );
          }

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Text('${restaurant['name']} 전체 메뉴',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          24, 4, 24, _totalCartCount > 0 ? 100 : 20),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          onTap: () => _showItemDetailModal(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
                                    const SizedBox(height: 6),
                                    Text('${_formatPrice(item.price)}원',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark)),
                                  ],
                                ),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.restaurant,
                                      color: Color(0xFF94A3B8), size: 24),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_totalCartCount > 0)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: InkWell(
                    onTap: () => setState(() => _currentScreen = 'cart'),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$_totalCartCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          const Expanded(
                              child: Center(
                                  child: Text('장바구니 보기',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)))),
                          Text('${_formatPrice(_totalCartPrice)}원',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // 메뉴 상세 모달
  // ══════════════════════════════════════════════════════════════════════
  void _showItemDetailModal(MenuItem menu) {
    int localQty = 1;
    List<String> options = [];
    int extras = 0;

    // 리뷰 Future는 모달 열릴 때 한 번만 생성
    final reviewsFuture = ApiService().getMenuReviews(menu.id);
    final outerContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Column(
              children: [
                // 드래그 핸들 + 닫기 버튼 (고정)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 14, 8, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFF94A3B8), size: 22),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                ),
                // 스크롤 가능한 본문
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    children: [
                      // 메뉴 이미지 + 정보
                      Row(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.restaurant,
                                color: Color(0xFF94A3B8), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(menu.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text(menu.description,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textLight)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                        '${menu.rating.toStringAsFixed(1)} (${menu.reviewCount})',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textLight)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                    '${_formatPrice(menu.price)}원',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                            height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // 리뷰 미리보기 섹션
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('리뷰',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                    '총 ${menu.reviewCount}개',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              Navigator.push(
                                outerContext,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(
                                    menuId: menu.id,
                                    menuName: menu.name,
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text('더보기',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textLight)),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.textLight),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<Map<String, dynamic>>(
                        future: reviewsFuture,
                        builder: (_, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 60,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            );
                          }
                          final reviews = (snap.data?['reviews']
                                  as List<dynamic>?) ??
                              [];
                          if (reviews.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Text('아직 리뷰가 없습니다.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textLight)),
                            );
                          }
                          final first =
                              reviews.first as Map<String, dynamic>;
                          final username =
                              first['username']?.toString() ??
                                  '단국대생';
                          final rating =
                              (first['rating'] as num?)?.toInt() ??
                                  5;
                          final comment =
                              first['comment']?.toString() ?? '';
                          final imageUrl =
                              first['imageUrl']?.toString();
                          final dateRaw =
                              first['date'] ?? first['createdAt'];
                          String dateStr = '';
                          if (dateRaw != null) {
                            try {
                              final dt = DateTime.parse(
                                      dateRaw.toString())
                                  .toLocal();
                              dateStr =
                                  '${dt.month}/${dt.day}/${dt.year}';
                            } catch (_) {
                              dateStr = dateRaw.toString();
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textDark)),
                                    Text(dateStr,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: List.generate(
                                      5,
                                      (i) => Icon(
                                            i < rating
                                                ? Icons.star_rounded
                                                : Icons
                                                    .star_outline_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          )),
                                ),
                                if (imageUrl != null &&
                                    imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx2, e, st) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                                if (comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(comment,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                          height: 1.4)),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                            height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // 추가 선택
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('추가 선택',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('선택',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildOptionRow('공기밥 추가', 1000, options,
                          (val, price) => setModalState(() {
                                val
                                    ? options.add('공기밥 추가')
                                    : options.remove('공기밥 추가');
                                extras += price;
                              })),
                      _buildOptionRow('고기 추가', 2000, options,
                          (val, price) => setModalState(() {
                                val
                                    ? options.add('고기 추가')
                                    : options.remove('고기 추가');
                                extras += price;
                              })),
                      _buildOptionRow('맵게 해 주세요', 0, options,
                          (val, price) => setModalState(() {
                                val
                                    ? options.add('맵게 해 주세요')
                                    : options.remove('맵게 해 주세요');
                              })),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(
                            height: 1, color: Color(0xFFF1F5F9)),
                      ),

                      // 수량
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('수량',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove,
                                      size: 16,
                                      color: AppColors.textDark),
                                  onPressed: () => setModalState(() {
                                    if (localQty > 1) localQty--;
                                  }),
                                ),
                                Text('$localQty',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textDark)),
                                IconButton(
                                  icon: const Icon(Icons.add,
                                      size: 16,
                                      color: AppColors.textDark),
                                  onPressed: () =>
                                      setModalState(() => localQty++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 장바구니 담기 버튼 (고정 하단)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(
                            color: Color(0xFFF1F5F9), width: 1)),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        cartList.add(CartItem(
                          menu: menu,
                          quantity: localQty,
                          selectedOptions: List.from(options),
                          extraCharges: extras,
                        ));
                      });
                      Navigator.pop(sheetCtx);
                    },
                    child: Text(
                      '${_formatPrice((menu.price + extras) * localQty)}원 장바구니 담기',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(
      String title, int price, List<String> current, Function(bool, int) onChange) {
    final selected = current.contains(title);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: AppColors.primary,
                shape: const CircleBorder(),
                onChanged: (val) => onChange(val ?? false, val! ? price : -price),
              ),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          Text(price > 0 ? '+${_formatPrice(price)}원' : '추가금 없음',
              style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // VIEW 3: 장바구니
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCartScreen() {
    final firstItem = cartList.isNotEmpty ? cartList.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => setState(() => _currentScreen = 'menu'),
        ),
        title: const Text('장바구니',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      body: cartList.isEmpty
          ? const Center(
              child: Text('장바구니가 비어 있습니다.',
                  style: TextStyle(color: AppColors.textLight)))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedRestaurant?['name']} >',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textDark),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: Color(0xFF94A3B8)),
                                  onPressed: () =>
                                      setState(() => cartList.clear()),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFFF1F5F9)),
                            ...cartList.map((item) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.restaurant,
                                            color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.menu.name,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.textDark)),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${_formatPrice(item.menu.price + item.extraCharges)}원',
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0)),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove,
                                                  size: 14),
                                              onPressed: () => setState(() {
                                                if (item.quantity > 1) {
                                                  item.quantity--;
                                                } else {
                                                  cartList.remove(item);
                                                }
                                              }),
                                            ),
                                            Text('${item.quantity}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark)),
                                            IconButton(
                                              icon: const Icon(Icons.add,
                                                  size: 14),
                                              onPressed: () =>
                                                  setState(() => item.quantity++),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('총 결제 금액',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500)),
                          Text('${_formatPrice(_totalCartPrice)}원',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                restaurantName:
                                    _selectedRestaurant?['name'] ?? '학생식당',
                                totalAmount: _totalCartPrice,
                                itemName: firstItem?.menu.name ?? '',
                                itemQuantity: firstItem?.quantity ?? 1,
                                itemPrice: firstItem?.menu.price ?? 0,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${_formatPrice(_totalCartPrice)}원 결제하기',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
