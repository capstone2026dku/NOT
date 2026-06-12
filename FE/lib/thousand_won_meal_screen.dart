// lib/thousand_won_meal_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'cart_screen.dart';

class ThousandWonMealScreen extends StatefulWidget {
  const ThousandWonMealScreen({Key? key}) : super(key: key);

  @override
  State<ThousandWonMealScreen> createState() => _ThousandWonMealScreenState();
}

class _ThousandWonMealScreenState extends State<ThousandWonMealScreen> {
  // Static menu items matching your design
  final List<Map<String, dynamic>> morningMenus = [
    {'name': '제육덮밥', 'price': '1,000원'},
    {'name': '스팸마요 덮밥', 'price': '1,000원'},
  ];

  // Helper method to display the Kiosk Student Validation Modal
  void _showQrValidationModal(BuildContext context) async {
    final userInfo = await ApiService.getUserInfo();
    final studentId = userInfo['studentId'] ?? '';
    final userName = userInfo['name'] ?? '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        int remainingSec = 179; // 02:59
        Timer? timer;

        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (remainingSec > 0) {
                setState(() => remainingSec--);
              } else {
                timer?.cancel();
                Navigator.pop(context);
              }
            });

            final min = (remainingSec ~/ 60).toString().padLeft(2, '0');
            final sec = (remainingSec % 60).toString().padLeft(2, '0');
            final isLow = remainingSec <= 30;

            return PopScope(
              onPopInvokedWithResult: (didPop, result) => timer?.cancel(),
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 36),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 22),
                          onPressed: () {
                            timer?.cancel();
                            Navigator.pop(context);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const Text(
                        '단국대학교',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$userName ($studentId)',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Icon(Icons.qr_code_2_rounded, size: 180, color: AppColors.textDark.withOpacity(0.9)),
                      ),
                      const Text('인증 유효시간', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        '$min:$sec',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isLow ? Colors.redAccent : AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '키오스크 스캐너에 위 QR코드를 인식시켜주세요.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 18),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text('천원의 학식', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
  centerTitle: true,
  backgroundColor: Colors.white,
  elevation: 0,
  // 👇 ADD THIS ACTIONS BAR HERE
  actions: [
    IconButton(
      icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textDark, size: 22),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CartScreen(menuName: '제육덮밥', priceString: '1,000원'),
          ),
        );
      },
    ),
    const SizedBox(width: 8),
  ],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(1),
    child: Container(color: const Color(0xFFE2E8F0), height: 0.5),
  ),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Title Text Section
            RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: 'Pretendard', fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.35),
                children: [
                  TextSpan(text: '든든한 아침,\n단돈 '),
                  TextSpan(text: '천원', style: TextStyle(color: AppColors.primary)),
                  TextSpan(text: '에!'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Program Guideline Informational Box Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuidelineRow('이용 대상', '단국대학교 학부 재학생'),
                        _buildGuidelineRow('이용 시간', '평일 08:00 부터 (선착순 100명)'),
                        _buildGuidelineRow('이용 방법', '모바일 앱으로 선결제하거나, 현장 키오스크 결제 시 아래의 오프라인 인증을 활용하세요.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Mobile Order Section Header Banner Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('오늘의 메뉴 주문하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                  child: const Text('모바일 주문', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 16),

            // 4. Breakfast Available Menu List View Node Builder
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: morningMenus.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = morningMenus[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(item['price'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                      GestureDetector(
                        //  AFTER (Triggers your cart checkout sequence cleanly!)
                        onTap: () {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) => CartScreen(
                          menuName: item['name'],
                          priceString: item['price'],
                        ),
                      ),
                    );
                  },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: AppColors.primary, size: 20),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 5. On-site Kiosk QR Action Module Button Core Section
            const Text('현장 키오스크 이용 시', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _showQrValidationModal(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Matches dark slate color context
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      '재학생 인증 QR 열기',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nested inline structural text block configuration row helper
  Widget _buildGuidelineRow(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Pretendard', fontSize: 13, height: 1.45, color: Color(0xFF475569)),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            TextSpan(text: content, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}