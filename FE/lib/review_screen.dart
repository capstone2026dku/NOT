// lib/screens/review_screen.dart
import 'package:flutter/material.dart';
import '../api_service.dart';

class ReviewScreen extends StatelessWidget {
  final int menuId;
  final String menuName;
  final ApiService apiService = ApiService();

  ReviewScreen({Key? key, required this.menuId, required this.menuName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('리뷰', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: apiService.getMenuReviews(menuId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('리뷰를 불러오지 못했습니다 😢'));
          }

          final data = snapshot.data!;
          final List reviewsList = data['reviews'] ?? [];
          final double averageRating = (data['average_rating'] ?? 4.8).toDouble();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(menuName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(width: 4),
                    Text('$averageRating', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('총 ${reviewsList.length}개의 리뷰', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                const Divider(thickness: 1, color: Color(0xFFF5F5F5)),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviewsList.length,
                  itemBuilder: (context, index) {
                    final review = reviewsList[index];
                    return _buildReviewCard(review);
                  },
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.grey[700],
        unselectedItemColor: Colors.grey[400],
        currentIndex: 2, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), label: '식권'),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '주문 내역'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '내 정보'),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
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
          Row(
            children: [
              Text(review['username'] ?? '단국대생', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${review['orderCount'] ?? 1}번째 주문', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(review['date'] ?? '2026/06/10', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              int rating = review['rating'] ?? 5;
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 12),
          if (review['imageUrl'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                review['imageUrl'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(review['comment'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }
}