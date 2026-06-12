// lib/cart_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'payment_screen.dart'; 

class CartScreen extends StatefulWidget {
  final String menuName;
  final String priceString;

  const CartScreen({
    Key? key,
    required this.menuName,
    required this.priceString,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int itemQuantity = 1;

  @override
  Widget build(BuildContext context) {
    // Extracts clean numerical values from strings (e.g., "7,500원" -> 7500)
    final int basePrice = int.tryParse(widget.priceString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final int calculatedTotal = basePrice * itemQuantity;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '장바구니', 
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 식당명 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Row(
                            children: [
                              const Text('천원의 학식',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark)),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: AppColors.textMuted),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        // 메뉴 아이템
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fastfood_rounded,
                                    color: Color(0xFFCBD5E1), size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.menuName,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
                                    const SizedBox(height: 4),
                                    Text(widget.priceString,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(7),
                                      icon: const Icon(Icons.remove,
                                          size: 14, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        if (itemQuantity > 1) {
                                          setState(() => itemQuantity--);
                                        }
                                      },
                                    ),
                                    Text('$itemQuantity',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark)),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(7),
                                      icon: const Icon(Icons.add,
                                          size: 14, color: Color(0xFF64748B)),
                                      onPressed: () =>
                                          setState(() => itemQuantity++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FIXED BOTTOM TOTAL BAR CONTAINER
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1), // Safely placed inside BoxDecoration
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '총 결제 금액', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textLight),
                    ),
                    Text(
                      '${_formatPriceWithCommas(calculatedTotal)}원', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Navigate forward cleanly to your payment view screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          restaurantName: '천원의 학식 (학생식당)',
                          totalAmount: calculatedTotal,
                          itemName: widget.menuName,
                          itemQuantity: itemQuantity,
                          itemPrice: basePrice,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '✓  ${_formatPriceWithCommas(calculatedTotal)}원 결제하기',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Formatting Helper: Adds thousand separator commas cleanly to integers
  String _formatPriceWithCommas(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), 
      (Match m) => "${m[1]},"
    );
  }
}