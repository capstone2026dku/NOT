import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _subView = 0; // 0=메인, 1=내가쓴리뷰, 2=문의하기

  bool _isEditingName = false;
  late TextEditingController _nameController;
  String _email = '';
  bool _loadingUser = true;

  final TextEditingController _inquiryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final info = await ApiService.getUserInfo();
    if (mounted) {
      setState(() {
        _nameController.text = info['name'] ?? '사용자';
        _email = info['studentId'] != null && info['studentId']!.isNotEmpty
            ? '${info['studentId']}@dankook.ac.kr'
            : '';
        _loadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inquiryController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _doLogout() async {
    await ApiService.logout();
    if (mounted) _navigateToLogin();
  }

  Future<void> _doDeleteAccount() async {
    await ApiService.deleteAccount();
    if (mounted) _navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (_subView == 1) return _buildReviewsView();
    if (_subView == 2) return _buildInquiryView();
    return _buildMainView();
  }

  // ─── 메인 화면 ────────────────────────────────────────────────
  Widget _buildMainView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _appBar('내 정보', showBack: false),
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // 프로필 카드
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F0FA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 16),
                      // 이름 편집
                      _isEditingName
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: TextField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.textDark),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isEditingName = false),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_nameController.text,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _isEditingName = true),
                                  child: const Icon(Icons.edit_outlined,
                                      color: AppColors.textMuted, size: 18),
                                ),
                              ],
                            ),
                      const SizedBox(height: 12),
                      // 이메일 배지
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mail_outline_rounded,
                                size: 14, color: AppColors.textLight),
                            const SizedBox(width: 6),
                            Text(_email,
                                style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 메뉴 카드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _menuRow(
                        icon: Icons.star_border_rounded,
                        iconColor: const Color(0xFFEAB308),
                        iconBg: const Color(0xFFFEF9C3),
                        label: '내가 쓴 리뷰',
                        onTap: () => setState(() => _subView = 1),
                      ),
                      _divider(),
                      _menuRow(
                        icon: Icons.key_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        iconBg: const Color(0xFFEFF6FF),
                        label: '비밀번호 변경',
                        onTap: () {},
                      ),
                      _divider(),
                      _menuRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: const Color(0xFF22C55E),
                        iconBg: const Color(0xFFDCFCE7),
                        label: '문의하기',
                        onTap: () => setState(() => _subView = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 계정 액션 카드
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _menuRow(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.textLight,
                        iconBg: const Color(0xFFF1F5F9),
                        label: '로그아웃',
                        showArrow: false,
                        onTap: () => _showConfirmDialog(isLogout: true),
                      ),
                      _divider(),
                      _menuRow(
                        icon: Icons.person_remove_outlined,
                        iconColor: const Color(0xFFEF4444),
                        iconBg: const Color(0xFFFEE2E2),
                        label: '회원 탈퇴',
                        labelColor: const Color(0xFFEF4444),
                        showArrow: false,
                        onTap: () => _showConfirmDialog(isLogout: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ─── 내가 쓴 리뷰 ──────────────────────────────────────────────
  Widget _buildReviewsView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _appBar('내가 쓴 리뷰',
          onBack: () => setState(() => _subView = 0)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _reviewCard('51장국밥', '고기만국밥', '2026-05-18', 5,
              '항상 맛있게 먹고 있습니다! 국물도 진하고 고기 양도 많아서 든든하게 먹었어요.'),
          const SizedBox(height: 14),
          _reviewCard('바비든든', '제육덮밥', '2026-05-15', 4,
              '양도 많고 불맛도 살짝 나서 좋네요. 가성비 최고!'),
        ],
      ),
    );
  }

  // ─── 문의하기 ──────────────────────────────────────────────────
  Widget _buildInquiryView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _appBar('문의하기',
          onBack: () => setState(() => _subView = 0)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 안내 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 13,
                      height: 1.6,
                      fontFamily: 'Pretendard'),
                  children: [
                    const TextSpan(
                        text: '서비스 이용 중 불편하신 점이나 건의사항을 남겨주세요.\n확인 후 '),
                    TextSpan(
                      text: _email,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
                    ),
                    const TextSpan(text: '로 신속하게 답변해 드리겠습니다.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 입력 박스
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _inquiryController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '여기에 내용을 입력해주세요.',
                    hintStyle: TextStyle(
                        color: Color(0xFFCBD5E1), fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _inquiryController.text.trim().isNotEmpty
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _inquiryController.text.trim().isNotEmpty
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('문의가 접수되었습니다.')),
                        );
                        _inquiryController.clear();
                        setState(() {});
                      }
                    : null,
                child: Text(
                  '문의 보내기',
                  style: TextStyle(
                    color: _inquiryController.text.trim().isNotEmpty
                        ? Colors.white
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 로그아웃/탈퇴 다이얼로그 ──────────────────────────────────
  void _showConfirmDialog({required bool isLogout}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isLogout
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLogout
                      ? Icons.logout_rounded
                      : Icons.person_remove_outlined,
                  color: isLogout
                      ? AppColors.textDark
                      : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isLogout ? '로그아웃 하시겠습니까?' : '정말 탈퇴하시겠습니까?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              if (isLogout)
                const Text(
                  '계정에서 로그아웃되며,\n초기 로그인 화면으로 이동합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textLight, fontSize: 13, height: 1.5),
                )
              else
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontFamily: 'Pretendard'),
                    children: [
                      TextSpan(
                        text: '탈퇴 시 모든 정보가 영구적으로 삭제되며,\n',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      TextSpan(
                        text: '다시 정보를 불러올 수 없습니다.',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLogout
                            ? AppColors.primary
                            : const Color(0xFFEF4444),
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        if (isLogout) {
                          await _doLogout();
                        } else {
                          await _doDeleteAccount();
                        }
                      },
                      child: Text(
                        isLogout ? '로그아웃' : '탈퇴하기',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 공통 헬퍼 ─────────────────────────────────────────────────
  PreferredSizeWidget _appBar(String title,
      {bool showBack = true, VoidCallback? onBack}) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark, size: 18),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: Text(title,
          style: const TextStyle(
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
    );
  }

  Widget _divider() => const Divider(
      height: 1, color: Color(0xFFF1F5F9), indent: 16, endIndent: 16);

  Widget _menuRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
    Color labelColor = AppColors.textDark,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor)),
            ),
            if (showArrow)
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(String restaurant, String dish, String date,
      int stars, String comment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(restaurant,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              Text(date,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(dish,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(Icons.star_rounded,
                  color: i < stars
                      ? const Color(0xFFFFB800)
                      : const Color(0xFFE2E8F0),
                  size: 18),
            ),
          ),
          const SizedBox(height: 12),
          Text(comment,
              style: const TextStyle(
                  color: Color(0xFF475569), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
