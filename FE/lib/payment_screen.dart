// lib/payment_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'order_history_screen.dart';
import 'toss_payment_webview.dart';

const _tossClientKey = 'test_ck_6bJXmgo28emdo5DLoL0A8LAnGKWx';
const _tossBlue = Color(0xFF0064FF);

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
  String selectedMethod = '토스페이';
  Map<String, dynamic>? _selectedTicket;

  String _orderNumber = '';
  int _estimatedWaitSec = 0;
  bool _isLoading = false;

  List<dynamic> _dbTickets = [];
  bool _ticketsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _ticketsLoading = true);
    try {
      final tickets = await ApiService.getTickets();
      final now = DateTime.now();
      final available = tickets.where((t) {
        final status = t['status'] as String? ?? '';
        final validUntil = DateTime.tryParse(t['validUntil']?.toString() ?? '');
        return status == 'AVAILABLE' && (validUntil == null || now.isBefore(validUntil));
      }).toList();
      if (mounted) setState(() { _dbTickets = available; _ticketsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _ticketsLoading = false);
    }
  }

  String _formatPrice(int price) => price
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  bool get _canPay {
    if (selectedMethod == '토스페이') return true;
    return _selectedTicket != null &&
        (_selectedTicket!['amount'] as int) >= widget.totalAmount;
  }

  bool get _ticketInsufficient =>
      _selectedTicket != null &&
      (_selectedTicket!['amount'] as int) < widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    if (flowStep == 1) return _buildOrderSuccessScreen();
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
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
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
                        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('총 결제 금액',
                              style: TextStyle(
                                  color: AppColors.textLight, fontSize: 14)),
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
                _buildTossPayTile(),
                const SizedBox(height: 12),
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
              onPressed: (_canPay && !_isLoading) ? _onPayPressed : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _getButtonLabel(),
                      style: TextStyle(
                          color: selectedMethod == '토스페이'
                              ? Colors.white
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

  Widget _buildTossPayTile() {
    final bool isSelected = selectedMethod == '토스페이';
    return GestureDetector(
      onTap: () => setState(() {
        selectedMethod = '토스페이';
        _selectedTicket = null;
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
                color: _tossBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('T',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('토스페이',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark)),
                  SizedBox(height: 2),
                  Text('토스 간편결제',
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
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFCBD5E1),
                  size: 22,
                ),
              ],
            ),
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
              if (_ticketsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_dbTickets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '등록된 식권이 없습니다. 식권 관리에서 등록해주세요.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                )
              else
                ..._dbTickets.map((t) => _buildTicketOption(t as Map<String, dynamic>)),
              const SizedBox(height: 10),
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
                            color: Colors.red, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildTicketOption(Map<String, dynamic> ticket) {
    final String id = ticket['id']?.toString() ?? '';
    final int amount = (ticket['amount'] as num?)?.toInt() ?? 0;
    final String ticketNumber = ticket['ticketNumber']?.toString() ?? '';
    final String? validUntilRaw = ticket['validUntil']?.toString();
    final DateTime? validUntil =
        validUntilRaw != null ? DateTime.tryParse(validUntilRaw) : null;
    final String periodStr = validUntil != null
        ? '~${validUntil.year}.${validUntil.month.toString().padLeft(2, '0')}.${validUntil.day.toString().padLeft(2, '0')}'
        : '';
    final bool isSelected = _selectedTicket?['id'] == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedTicket = ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_formatPrice(amount)}원권',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('$ticketNumber  $periodStr',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
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

  Color _getButtonColor() {
    if (!_canPay) return const Color(0xFFE2E8F0);
    if (selectedMethod == '토스페이') return _tossBlue;
    return AppColors.primary;
  }

  String _getButtonLabel() {
    if (selectedMethod == '토스페이') {
      return '${_formatPrice(widget.totalAmount)}원 토스페이 결제';
    }
    return '식권으로 결제하기';
  }

  void _onPayPressed() {
    if (selectedMethod == '토스페이') {
      _openTossPayment();
    } else {
      _sendOrderToBackend();
    }
  }

  void _openTossPayment() {
    // TossPay에 전달할 고유 주문 ID (타임스탬프 기반)
    final tossOrderId = 'danbab-${DateTime.now().millisecondsSinceEpoch}';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TossPaymentWebView(
          clientKey: _tossClientKey,
          amount: widget.totalAmount,
          orderId: tossOrderId,
          orderName: widget.itemName,
          onSuccess: (paymentKey, orderId, amount) {
            Navigator.of(context).pop(); // WebView 닫기
            _sendOrderToBackend(paymentKey: paymentKey, tossOrderId: orderId);
          },
          onFail: (code, message) {
            Navigator.of(context).pop(); // WebView 닫기
            if (code != 'USER_CANCEL') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('결제 실패: $message'),
                    backgroundColor: Colors.redAccent),
              );
            }
          },
        ),
      ),
    );
  }

  // ─── STEP 1: 주문 완료 ────────────────────────────────────────────────────
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
                  style: TextStyle(fontSize: 14, color: AppColors.textLight)),
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
                    Text(_orderNumber.isNotEmpty ? _orderNumber : '-',
                        style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    const Text('예상 대기 시간',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                        _estimatedWaitSec > 0
                            ? '${(_estimatedWaitSec / 60).ceil()}분'
                            : '-',
                        style: const TextStyle(
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

  void _sendOrderToBackend({String? paymentKey, String? tossOrderId}) async {
    setState(() => _isLoading = true);

    final orderPayload = {
      "restaurantName": widget.restaurantName,
      "itemName": widget.itemName,
      "quantity": widget.itemQuantity,
      "totalPrice": widget.totalAmount,
      "paymentMethod": selectedMethod == '토스페이' ? "toss" : "meal_ticket",
      if (selectedMethod == '토스페이' && paymentKey != null)
        "paymentKey": paymentKey,
      if (selectedMethod == '토스페이' && tossOrderId != null)
        "tossOrderId": tossOrderId,
      if (selectedMethod != '토스페이' && _selectedTicket != null)
        "ticketId": _selectedTicket!['id'],
    };

    try {
      final result = await _apiService.submitPreOrder(orderPayload);
      final orderNumber = result['orderNumber']?.toString() ?? '';
      final estimatedWaitSec =
          (result['estimatedWaitSec'] as num?)?.toInt() ?? 0;
      await NotificationService.showOrderAccepted(
        restaurantName: widget.restaurantName,
        itemName: widget.itemName,
        quantity: widget.itemQuantity,
        totalAmount: widget.totalAmount,
      );
      if (mounted) {
        setState(() {
          _orderNumber = orderNumber;
          _estimatedWaitSec = estimatedWaitSec;
          flowStep = 1;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('주문 실패: $error'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
