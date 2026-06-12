// lib/home_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'cafeteria_menu_screen.dart';
import 'thousand_won_meal_screen.dart'; // 🔥 CHANGED: Pointing to your newly built 1,000 Won screen
import 'ai_menu_screen.dart';
import 'order_history_screen.dart';
import 'notification_service.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _hasUnreadNotification = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadFlag();
  }

  Future<void> _loadUnreadFlag() async {
    final hasUnread = await NotificationService.hasUnread();
    if (mounted) setState(() => _hasUnreadNotification = hasUnread);
  }

  Future<void> _onBellTapped() async {
    await NotificationService.clearUnread();
    if (!mounted) return;
    setState(() => _hasUnreadNotification = false);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row (Greeting Text & Notification Bell)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '어떤 서비스를\n이용하러 오셨나요?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.35,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onBellTapped,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_rounded, size: 22, color: AppColors.textDark),
                          if (_hasUnreadNotification)
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 2. Large Student Cafeteria Main Card (학생식당)
              SizedBox(
                width: double.infinity,
                child: _buildFeatureTile(
                  context: context,
                  height: 150, 
                  color: AppColors.primary,
                  title: '학생식당',
                  titleColor: Colors.white,
                  iconData: Icons.restaurant_rounded,
                  iconBgColor: Colors.white.withValues(alpha: 0.12),
                  iconColor: Colors.white.withValues(alpha: 0.6),
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen())
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 3. Grid Row (Café Split & 1000W Breakfast Split)
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureTile(
                      context: context,
                      height: 130,
                      color: Colors.white,
                      title: '카페',
                      titleColor: AppColors.textDark,
                      iconData: Icons.local_cafe_outlined,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: AppColors.primary,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureTile(
                      context: context,
                      height: 130,
                      color: Colors.white,
                      title: '천원의\n학식',
                      titleColor: AppColors.textDark,
                      iconData: Icons.storefront_outlined,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: AppColors.primary,
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(builder: (_) => const ThousandWonMealScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. AI Smart Recommendation Row Card (AI 스마트 추천)
              SizedBox(
                width: double.infinity,
                child: _buildFeatureTile(
                  context: context,
                  height: 95,
                  color: Colors.white,
                  title: 'AI 스마트 추천',
                  subtitle: '맞춤형 메뉴 제안',
                  titleColor: AppColors.textDark,
                  iconData: Icons.auto_awesome_outlined,
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconColor: AppColors.primary,
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const AiMenuScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Universal custom tile builder matching layout constraints
  Widget _buildFeatureTile({
    required BuildContext context,
    required double height,
    required Color color,
    required String title,
    String? subtitle,
    required Color titleColor,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isMainCafeteria = title == '학생식당';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // Forces the whole area to accept touch events
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Circle Graphic Layer
              Positioned(
                right: isMainCafeteria ? -24 : -16, 
                bottom: isMainCafeteria ? -24 : -16,
                child: Container(
                  width: isMainCafeteria ? 120 : 76,
                  height: isMainCafeteria ? 120 : 76,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Align(
                    alignment: const Alignment(-0.25, -0.25),
                    child: Icon(iconData, size: isMainCafeteria ? 52 : 32, color: iconColor),
                  ),
                ),
              ),

              // Text Labels Layer
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: subtitle != null ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    if (subtitle != null) ...[
                      Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: subtitle != null ? 15 : 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}