// lib/main.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'ticket_screen.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const DanbabApp());
}

class DanbabApp extends StatelessWidget {
  const DanbabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '단밥 (Danbab)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
      ),
      // 저장된 토큰이 있으면 메인 화면, 없으면 로그인 화면
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter({Key? key}) : super(key: key);

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final token = await ApiService.getAccessToken();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? const MainNavigationShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _appScreens = [
    const HomeDashboardScreen(),
   /// const TicketScreen(),
    const OrderHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _appScreens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
                icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.home_outlined)),
                activeIcon: Icon(Icons.home),
                label: '홈'),
            BottomNavigationBarItem(
                icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.confirmation_num_outlined)),
                activeIcon: Icon(Icons.confirmation_num),
                label: '식권'),
            BottomNavigationBarItem(
                icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.description_outlined)),
                activeIcon: Icon(Icons.description),
                label: '주문 내역'),
            BottomNavigationBarItem(
                icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_outline_rounded)),
                activeIcon: Icon(Icons.person),
                label: '내 정보'),
          ],
        ),
      ),
    );
  }
}
