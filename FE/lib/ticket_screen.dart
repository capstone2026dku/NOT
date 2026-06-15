// lib/review_write_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String menuName;
  final String restaurantName;

  const ReviewWriteScreen({
    super.key,
    required this.menuName,
    required this.restaurantName,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  int _stars = 0;
  final TextEditingController _textCtrl = TextEditingController();

  bool get _canSubmit => _textCtrl.text.trim().isNotEmpty && _stars > 0;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '리뷰 작성',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(widget.menuName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final selected = i < _stars;
                  return IconButton(
                    onPressed: () => setState(() => _stars = i + 1),
                    icon: Icon(
                      Icons.star,
                      size: 36,
                      color: selected ? Colors.amber : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _textCtrl,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '리뷰 작성',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_outlined),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canSubmit
                    ? () => Navigator.pop(context, {
                          'rating': _stars,
                          'comment': _textCtrl.text.trim(),
                        })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _canSubmit ? AppColors.primary : Colors.grey[300],
                ),
                child: const Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}