import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'cart_screen.dart';

class ThousandWonMealScreen extends StatefulWidget {
  const ThousandWonMealScreen({super.key});

  @override
  State<ThousandWonMealScreen> createState() => _ThousandWonMealScreenState();
}

class _ThousandWonMealScreenState extends State<ThousandWonMealScreen> {
  final List<Map<String, dynamic>> morningMenus = [
    {'name': '제육덮밥', 'price': '1,000원'},
    {'name': '스팸마요 덮밥', 'price': '1,000원'},
  ];

  void _showQrValidationModal(BuildContext context) async {
    final userInfo = await ApiService.getUserInfo();
    final studentId = userInfo['studentId'] ?? '';
    final userName = userInfo['name'] ?? '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        int remainingSec = 179;
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

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          timer?.cancel();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    Text('$userName ($studentId)'),
                    const SizedBox(height: 20),
                    const Icon(Icons.qr_code_2_rounded, size: 160),
                    const SizedBox(height: 20),
                    Text('$min:$sec'),
                  ],
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
        title: const Text('천원의 학식'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CartScreen(
                    menuName: '제육덮밥',
                    priceString: '1,000원',
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: morningMenus.length,
        itemBuilder: (context, index) {
          final item = morningMenus[index];

          return ListTile(
            title: Text(item['name']),
            subtitle: Text(item['price']),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartScreen(
                      menuName: item['name'],
                      priceString: item['price'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}