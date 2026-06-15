// lib/order_history_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'review_write_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  List<dynamic> get _activeOrders => _allOrders
      .where((o) => _isActiveOrder(o['status'] as String))
      .toList();

  List<dynamic> get _pastOrders => _allOrders
      .where((o) => !_isActiveOrder(o['status'] as String))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await ApiService.getMyOrders();
      if (mounted) setState(() { _allOrders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}. ${dt.month}. ${dt.day}.';
    } catch (_) {
      return iso;
    }
  }

  bool _isActiveOrder(String status) =>
      status == 'PAID' || status == 'PARTIALLY_COMPLETED';

  String _mapItemsToStep(List<dynamic> items) {
    if (items.isEmpty) return '접수 대기';
    final statuses = items.map((i) => i['status'] as String).toList();
    if (statuses.every((s) => s == 'COMPLETED')) return '조리 완료';
    if (statuses.any((s) => s == 'COOKING')) return '조리 중';
    return '접수 대기';
  }

  String _orderNumber(Map<String, dynamic> order) {
    final items = (order['orderItems'] as List<dynamic>?) ?? [];
    if (items.isNotEmpty) {
      final num = items.first['orderNumber'];
      if (num != null) return num.toString();
    }
    final id = order['id']?.toString() ?? '';
    return id.length > 6 ? id.substring(id.length - 6) : id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('주문 내역',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Pretendard'),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'Pretendard'),
          tabs: [
            Tab(child: _activeTabLabel()),
            const Tab(text: '과거 주문 내역'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textDark, size: 20),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textLight, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(_activeOrders),
                    _buildPastTab(_pastOrders),
                  ],
                ),
    );
  }

  Widget _activeTabLabel() {
    final count = _activeOrders.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('진행 중 주문'),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1: 진행 중인 주문
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildActiveTab(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('진행 중인 주문이 없습니다.',
            style: TextStyle(color: AppColors.textLight, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index] as Map<String, dynamic>;
        final items = (order['orderItems'] as List<dynamic>?) ?? [];
        final statusLabel = _mapItemsToStep(items);
        final stepIndex =
            statusLabel == '조리 완료' ? 2 : statusLabel == '조리 중' ? 1 : 0;
        final orderNum = _orderNumber(order);
        final totalPrice = order['totalPrice'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파란 헤더
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('주문 번호 $orderNum',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(statusLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    GestureDetector(
                      onTap: _loadOrders,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sync_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상태 스테퍼
                    _buildStepper(stepIndex),
                    const SizedBox(height: 16),

                    // 조리 완료 알림 OR 대기번호/예상대기 카드
                    if (stepIndex == 2)
                      _buildReadyNotification()
                    else
                      _buildWaitInfo(orderNum, _extractWaitTime(order)),

                    const SizedBox(height: 16),
                    const Text('주문 상세 내역',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final name = item['menu']?['name'] ?? '메뉴';
                      final qty = item['quantity'] as int? ?? 1;
                      final price = item['unitPrice'] as int? ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                    fontFamily: 'Pretendard'),
                                children: [
                                  TextSpan(text: name),
                                  TextSpan(
                                    text: ' x$qty',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text('${_formatPrice(price * qty)}원',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('총 결제 금액',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textLight)),
                        Text('${_formatPrice(totalPrice)}원',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepper(int stepIndex) {
    return Row(
      children: [
        _buildStepIcon(0, Icons.receipt_long_rounded, '접수 대기', stepIndex),
        _buildStepLine(isPassed: stepIndex > 0),
        _buildStepIcon(1, Icons.restaurant_rounded, '조리 중', stepIndex),
        _buildStepLine(isPassed: stepIndex > 1),
        _buildStepIcon(
            2, Icons.check_circle_outline_rounded, '조리 완료', stepIndex),
      ],
    );
  }

  Widget _buildStepIcon(
      int index, IconData icon, String label, int currentStep) {
    final bool isDone = currentStep >= index;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          child: Icon(icon,
              size: 17,
              color: isDone ? Colors.white : const Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isDone ? FontWeight.bold : FontWeight.w500,
                color: isDone
                    ? AppColors.textDark
                    : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildStepLine({required bool isPassed}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Container(
          height: 2,
          color: isPassed ? AppColors.primary : const Color(0xFFE2E8F0),
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }

  String _extractWaitTime(Map<String, dynamic> order) {
    final raw = order['estimatedWaitTime'] ??
        order['waitTime'] ??
        order['estimatedMinutes'];
    if (raw == null) return '–';
    return '$raw분';
  }

  Widget _buildWaitInfo(String orderNum, String waitTime) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('대기 번호',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(orderNum,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('예상 대기',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 16, color: Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    Text(waitTime,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadyNotification() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('음식이 준비되었습니다!',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                SizedBox(height: 2),
                Text('배식구에서 주문 번호를 확인해주세요.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2: 과거 주문 내역
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildPastTab(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('과거 주문 내역이 없습니다.',
            style: TextStyle(color: AppColors.textLight, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index] as Map<String, dynamic>;
        final items = (order['orderItems'] as List<dynamic>?) ?? [];
        final totalPrice = order['totalPrice'] as int? ?? 0;
        final dateStr = _formatDate(
            order['paidAt'] as String? ?? order['createdAt'] as String?);
        final orderNum = _orderNumber(order);
        final status = order['status'] as String? ?? '';
        final isCancelled = status == 'CANCELLED';
        final statusLabel = isCancelled ? '취소됨' : '수령 완료';

        final restaurantName = items.isNotEmpty
            ? ((items.first['restaurant'] as Map?)?['name'] as String? ?? '')
            : '';
        final firstMenuName = items.isNotEmpty
            ? ((items.first['menu'] as Map?)?['name'] as String? ?? '')
            : '';
        final firstMenuId = items.isNotEmpty
            ? (items.first['menuId']?.toString() ?? '')
            : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 + 상태 + 주문번호
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isCancelled
                                  ? Icons.cancel_outlined
                                  : Icons.check_circle_outline_rounded,
                              color: isCancelled
                                  ? Colors.redAccent
                                  : AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isCancelled
                                        ? Colors.redAccent
                                        : AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                    Text('주문 번호 $orderNum',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              // 메뉴 목록
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Column(
                  children: items.map((item) {
                    final name =
                        (item['menu'] as Map?)?['name'] as String? ?? '메뉴';
                    final qty = item['quantity'] as int? ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                          Text('x$qty',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              // 총 결제 금액
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('총 결제 금액',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight)),
                    Text('${_formatPrice(totalPrice)}원',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ],
                ),
              ),
              // 리뷰 버튼
              if (!isCancelled)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _ReviewButton(
                    menuId: firstMenuId,
                    menuName: firstMenuName,
                    restaurantName: restaurantName,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── 리뷰 버튼 (작성 전/후 상태 보존) ──────────────────────────────────────────
class _ReviewButton extends StatefulWidget {
  final String menuId;
  final String menuName;
  final String restaurantName;

  const _ReviewButton(
      {required this.menuId, required this.menuName, required this.restaurantName});

  @override
  State<_ReviewButton> createState() => _ReviewButtonState();
}

class _ReviewButtonState extends State<_ReviewButton> {
  bool _reviewed = false;

  @override
  Widget build(BuildContext context) {
    if (_reviewed) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF94A3B8), size: 18),
            SizedBox(width: 6),
            Text('리뷰 작성 완료',
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
          ],
        ),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: AppColors.primary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        final done = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ReviewWriteScreen(
            menuId: widget.menuId,
            menuName: widget.menuName,
            restaurantName: widget.restaurantName,
          ),
        );
        if (done == true && mounted) setState(() => _reviewed = true);
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 6),
          Text('리뷰 작성하기',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
