// lib/review_write_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String menuId;
  final String menuName;
  final String restaurantName;

  const ReviewWriteScreen({
    Key? key,
    required this.menuId,
    required this.menuName,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  int _stars = 0;
  bool _submitting = false;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _stars > 0 && _textCtrl.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitReview(widget.menuId, _stars, _textCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 타이틀 + 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('리뷰 작성',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 메뉴명 박스
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('간단한 리뷰를 작성해 주세요!',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 3),
                Text(widget.menuName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // 별점
          Center(
            child: Column(
              children: [
                const Text('이 메뉴는 어떠셨나요?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _stars = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star_rounded,
                          size: 42,
                          color: (i + 1) <= _stars
                              ? Colors.amber
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 텍스트 입력
          TextField(
            controller: _textCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: '음식의 맛, 양, 포장 상태 등에 대한 솔직한 리뷰를 남겨주세요.',
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          // 사진 추가
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    color: AppColors.textMuted, size: 26),
                SizedBox(height: 4),
                Text('사진 추가',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 등록하기 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _canSubmit ? AppColors.primary : const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _canSubmit ? _submit : null,
            child: Text(
              _submitting ? '제출 중...' : '등록하기',
              style: TextStyle(
                color: _canSubmit ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
