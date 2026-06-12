// lib/screens/review_screen.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../app_theme.dart';

class ReviewScreen extends StatelessWidget {
  final String menuId;
  final String menuName;

  ReviewScreen({Key? key, required this.menuId, required this.menuName})
      : super(key: key);

  final ApiService _apiService = ApiService();

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('리뷰',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _apiService.getMenuReviews(menuId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('리뷰를 불러오지 못했습니다.',
                    style: TextStyle(color: AppColors.textLight)));
          }

          final data = snapshot.data ?? {};
          final List reviewsList = data['reviews'] ?? [];
          final double averageRating =
              (data['average_rating'] ?? 4.8).toDouble();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(menuName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 28),
                    const SizedBox(width: 6),
                    Text(averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('총 ${reviewsList.length}개의 리뷰',
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 13)),
                const SizedBox(height: 20),
                const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: reviewsList.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(
                        reviewsList[index] as Map<String, dynamic>);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: '홈'),
            BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_num_outlined), label: '식권'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined), label: '주문 내역'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded), label: '내 정보'),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final int rating = (review['rating'] as num?)?.toInt() ?? 5;
    final String username = review['username']?.toString() ?? '단국대생';
    final String dateStr = _formatDate(review['date'] ?? review['createdAt']);
    final String? imageUrl = review['imageUrl']?.toString();
    final String comment = review['comment']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 유저명 + 날짜
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textDark)),
              Text(dateStr,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          // 별점
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          // 이미지 (있을 때만)
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, e) => const SizedBox.shrink(),
              ),
            ),
          ],
          // 코멘트
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    height: 1.5)),
          ],
        ],
      ),
    );
  }
}
