// lib/payment_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'order_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String restaurantName;
  final int totalAmount;
  final String itemName;
  final int itemQuantity;
  final int itemPrice;

  const PaymentScreen({
    Key? key,
    required this.restaurantName,
    required this.totalAmount,
    required this.itemName,
    required this.itemQuantity,
    required this.itemPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();

  int flowStep = 0;
  String selectedMethod = '카카오페이';
  int? _selectedTicketValue;

  static const String _ticketPeriod = '2026.05.01 ~ 2026.12.31';
  static const List<Map<String, dynamic>> _tickets = [
    {'label': '5,000원권', 'value': 5000},
    {'label': '10,000원권', 'value': 10000},
    {'label': '15,000원권', 'value': 15000},
  ];

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  bool get _canPay {
    if (selectedMethod == '카카오페이') return true;
    return _selectedTicketValue != null &&
        _selectedTicketValue! >= widget.totalAmount;
  }

  bool get _ticketInsufficient =>
      _selectedTicketValue != null &&
      _selectedTicketValue! < widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    if (flowStep == 1) return _buildKakaoPayScreen();
    if (flowStep == 2) return _buildOrderSuccessScreen();
    return _buildOrderReviewScreen();
  }

  // ─── STEP 0: 결제 수단 선택 ─────────────────────────────────────────────────
  Widget _buildOrderReviewScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('결제하기',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 주문 내역 카드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('주문 내역',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child:
                            Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                  fontFamily: 'Pretendard'),
                              children: [
                                TextSpan(text: widget.itemName),
                                TextSpan(
                                  text: ' x${widget.itemQuantity}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Text('${_formatPrice(widget.totalAmount)}원',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textDark)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child:
                            Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('총 결제 금액',
                              style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14)),
                          Text('${_formatPrice(widget.totalAmount)}원',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text('결제 수단',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ),
                // 카카오페이 타일
                _buildKakaoPayTile(),
                const SizedBox(height: 12),
                // 모바일 식권 타일 (선택 시 확장)
                _buildMealTicketTile(),
              ],
            ),
          ),
          // 하단 결제 버튼
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _canPay ? _onPayPressed : null,
              child: Text(
                _getButtonLabel(),
                style: TextStyle(
                    color: selectedMethod == '카카오페이'
                        ? Colors.black
                        : (_canPay ? Colors.white : AppColors.textMuted),
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKakaoPayTile() {
    final bool isSelected = selectedMethod == '카카오페이';
    return GestureDetector(
      onTap: () => setState(() {
        selectedMethod = '카카오페이';
        _selectedTicketValue = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEB00),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('pay',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.black)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('카카오페이',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('카카오 간편결제',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTicketTile() {
    final bool isSelected = selectedMethod == '모바일 식권';
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = '모바일 식권'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // 타이틀 행
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined,
                      size: 18, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('모바일 식권',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text('단국대학교 모바일 식권',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textLight)),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color:
                      isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
            // 식권 선택 목록 (모바일 식권 선택 시 펼침)
            if (isSelected) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('사용할 식권을 선택해주세요',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              const SizedBox(height: 12),
              ..._tickets.map((t) => _buildTicketOption(
                    t['value'] as int,
                    t['label'] as String,
                  )),
              const SizedBox(height: 10),
              // 항상 표시되는 안내 박스
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('!',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '식권의 권면 가액 미만으로 결제 시,\n차액은 재사용하거나 환불받을 수 없습니다.',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              // 식권 금액 부족 에러
              if (_ticketInsufficient) ...[
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '선택한 식권 금액이 총 결제 금액보다 부족합니다.',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketOption(int value, String label) {
    final bool isSelected = _selectedTicketValue == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTicketValue = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('사용 가능 기간: $_ticketPeriod',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color:
                  isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    if (!_canPay) return const Color(0xFFE2E8F0);
    if (selectedMethod == '카카오페이') return const Color(0xFFFFEB00);
    return AppColors.primary;
  }

  String _getButtonLabel() {
    if (selectedMethod == '카카오페이') {
      return '${_formatPrice(widget.totalAmount)}원 카카오페이 결제';
    }
    return '식권으로 결제하기';
  }

  void _onPayPressed() {
    if (selectedMethod == '카카오페이') {
      setState(() => flowStep = 1);
    } else {
      _sendOrderToBackend();
    }
  }

  // ─── STEP 1: 카카오페이 확인 ─────────────────────────────────────────────────
  Widget _buildKakaoPayScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 18),
          onPressed: () => setState(() => flowStep = 0),
        ),
        title: const Text('결제하기',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFEB00),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('● pay',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black)),
                ),
                const SizedBox(height: 24),
                const Text('결제 금액',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text('${_formatPrice(widget.totalAmount)}원',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('카카오페이머니',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark)),
                            SizedBox(height: 2),
                            Text('잔액 150,000원',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFFFFEB00), size: 22),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEB00),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _sendOrderToBackend,
              child: Text('${_formatPrice(widget.totalAmount)}원 결제하기',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: 주문 완료 ────────────────────────────────────────────────────
  Widget _buildOrderSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF22C55E), size: 52),
              ),
              const SizedBox(height: 24),
              const Text('주문이 완료되었습니다!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('주방에서 메뉴를 준비하고 있습니다.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textLight)),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Text('대기 번호',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('834',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                          height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    const Text('예상 대기 시간',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('7분',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen()),
                  (route) => route.isFirst,
                ),
                child: const Text('주문 현황 확인하기',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _sendOrderToBackend() async {
    final orderPayload = {
      "restaurantName": widget.restaurantName,
      "itemName": widget.itemName,
      "quantity": widget.itemQuantity,
      "totalPrice": widget.totalAmount,
      "paymentMethod":
          selectedMethod == '카카오페이' ? "kakaopay" : "meal_ticket",
    };

    try {
      await _apiService.submitPreOrder(orderPayload);
      await NotificationService.showOrderAccepted(
        restaurantName: widget.restaurantName,
        itemName: widget.itemName,
        quantity: widget.itemQuantity,
        totalAmount: widget.totalAmount,
      );
      if (mounted) setState(() => flowStep = 2);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('서버 전송 실패: $error'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
