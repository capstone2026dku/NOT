import 'package:flutter/material.dart';
import 'app_theme.dart';

class BreakfastScreen extends StatelessWidget {
  const BreakfastScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('천원의 학식',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text('천원의 학식 상세 화면',
            style: TextStyle(color: AppColors.textLight)),
      ),
    );
  }
}
