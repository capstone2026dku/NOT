// lib/ticket_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'app_theme.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final List<Map<String, dynamic>> tickets = [
    {
      'amount': '5,000원',
      'location': '단국대 학생식당',
      'validity': '2026.05.10 ~ 2026.06.09',
      'ticketNumber': '12345678',
      'status': '사용 가능',
    }
  ];

  Set<String> get _existingTicketNumbers => tickets
      .map((ticket) => _normalizeTicketNumber(ticket['ticketNumber']?.toString() ?? ''))
      .where((number) => number.isNotEmpty)
      .toSet();

  static String _normalizeTicketNumber(String value) => value.trim().toUpperCase();

  void _showQrModal(BuildContext context, Map<String, dynamic> ticket) {
    final validity = ticket['validity']?.toString() ?? '';
    final endDate = validity.contains('~') ? validity.split('~').last.trim() : validity;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket['status']?.toString() ?? '사용 가능',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ticket['amount']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket['location']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _DashedDivider(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(Icons.qr_code_2_rounded, size: 160, color: AppColors.textDark),
                      Positioned(top: 0, left: 0, child: _CornerBracket()),
                      Positioned(top: 0, right: 0, child: _CornerBracket(flipH: true)),
                      Positioned(bottom: 0, left: 0, child: _CornerBracket(flipV: true)),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _CornerBracket(flipH: true, flipV: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '식권 번호',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ticket['ticketNumber']?.toString().split('').join(' ') ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '사용 기한',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '~ $endDate',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTicketRegister() async {
    final newTicket = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => TicketRegisterScreen(existingNumbers: _existingTicketNumbers),
      ),
    );

    if (newTicket != null && mounted) {
      setState(() => tickets.add(newTicket));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '내 식권',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Stack(
        children: [
          tickets.isEmpty
              ? const Center(
                  child: Text(
                    '보유 중인 식권이 없습니다.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        ticket['status']?.toString() ?? '사용 가능',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      ticket['amount']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      ticket['location']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showQrModal(context, ticket),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_2_rounded,
                                        size: 36,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '크게 보기',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ),
                          _InfoRow(label: '사용 기간', value: ticket['validity']?.toString() ?? ''),
                          const SizedBox(height: 6),
                          _InfoRow(
                            label: '식권 번호',
                            value: ticket['ticketNumber']?.toString() ?? '',
                          ),
                        ],
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                onPressed: _openTicketRegister,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  '식권 등록하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketRegisterScreen extends StatefulWidget {
  final Set<String> existingNumbers;

  const TicketRegisterScreen({super.key, this.existingNumbers = const {}});

  @override
  State<TicketRegisterScreen> createState() => _TicketRegisterScreenState();
}

class _TicketRegisterScreenState extends State<TicketRegisterScreen> {
  bool _isManualMode = false;
  bool _isLoading = false;
  String? _errorText;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _normalizeTicketNumber(String value) => value.trim().toUpperCase();

  String? _validate(String value) {
    final number = _normalizeTicketNumber(value);
    if (number.length < 6) return '최소 6자리 이상 입력해주세요.';
    if (number.length > 16) return '최대 16자리까지 입력 가능합니다.';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(number)) {
      return '영문과 숫자만 입력 가능합니다.';
    }
    if (widget.existingNumbers.contains(number)) {
      return '이미 등록된 식권 번호입니다.';
    }
    return null;
  }

  Map<String, dynamic> _ticketFromNumber(String ticketNumber) {
    return {
      'amount': '5,000원',
      'location': '단국대 학생식당',
      'validity': '2026.06.02 ~ 2026.07.02',
      'ticketNumber': ticketNumber,
      'status': '사용 가능',
    };
  }

  Future<void> _submitManual() async {
    final ticketNumber = _normalizeTicketNumber(_codeController.text);
    final error = _validate(ticketNumber);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    Navigator.pop(context, _ticketFromNumber(ticketNumber));
  }

  void _submitScannedTicket(Map<String, dynamic> ticket) {
    final ticketNumber = _normalizeTicketNumber(ticket['ticketNumber']?.toString() ?? '');
    final error = _validate(ticketNumber);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    Navigator.pop(context, {
      ...ticket,
      'ticketNumber': ticketNumber,
    });
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
        title: const Text(
          '식권 등록',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _isManualMode ? _buildManualInputLayout() : _buildQrScanLayout(),
    );
  }

  Widget _buildQrScanLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 44),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'QR 코드 스캔',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '실물 식권이나 모바일 식권을\n등록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
                  );
                  if (result != null && mounted) {
                    _submitScannedTicket(result);
                  }
                },
                icon: const Icon(Icons.crop_free_rounded, size: 18, color: Colors.white),
                label: const Text(
                  '카메라 켜기',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isManualMode = true),
                child: const Text(
                  '직접 번호 입력하기',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputLayout() {
    final hasInput = _codeController.text.trim().isNotEmpty;
    final hasError = _errorText != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '식권 번호 입력',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '영문과 숫자로 이루어진 6~16자리 번호를 입력해주세요.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(16),
            ],
            onChanged: (_) => setState(() => _errorText = null),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: '영문 및 숫자 입력 (6~16자리)',
              hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
              errorText: _errorText,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade300 : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasInput ? AppColors.primary : const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: (hasInput && !_isLoading) ? _submitManual : null,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    '등록 완료',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: hasInput ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _hasScanned = true;
    _controller.stop();
    Navigator.pop(context, _parseTicketData(rawValue));
  }

  Map<String, dynamic> _parseTicketData(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'amount': decoded['amount']?.toString() ?? '5,000원',
        'location': decoded['location']?.toString() ?? '단국대 학생식당',
        'validity': decoded['validity']?.toString() ?? '2026.06.02 ~ 2026.07.02',
        'ticketNumber': decoded['ticketNumber']?.toString() ?? raw,
        'status': decoded['status']?.toString() ?? '사용 가능',
      };
    } catch (_) {
      return {
        'amount': '5,000원',
        'location': '단국대 학생식당',
        'validity': '2026.06.02 ~ 2026.07.02',
        'ticketNumber': raw,
        'status': '사용 가능',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR 스캔',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, __) {
                final torchEnabled = state.torchState == TorchState.on;
                return Icon(
                  torchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: torchEnabled ? Colors.yellow : Colors.white,
                  size: 22,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScanFrameOverlay(),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '식권의 QR 코드를 사각형 안에 맞춰주세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: dashSpace),
              color: const Color(0xFFE2E8F0),
            ),
          ),
        );
      },
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final bool flipH;
  final bool flipV;

  const _CornerBracket({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: SizedBox(
        width: 18,
        height: 18,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 2.5, color: const Color(0xFF94A3B8)),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: 2.5, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrameOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const size = 240.0;
    const bracketLen = 28.0;
    const bracketThick = 3.5;
    const color = Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _Bracket(len: bracketLen, thick: bracketThick, color: color),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: color,
              flipH: true,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: color,
              flipV: true,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _Bracket(
              len: bracketLen,
              thick: bracketThick,
              color: color,
              flipH: true,
              flipV: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  final double len;
  final double thick;
  final Color color;
  final bool flipH;
  final bool flipV;

  const _Bracket({
    required this.len,
    required this.thick,
    required this.color,
    this.flipH = false,
    this.flipV = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: len,
        height: len,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: thick, color: color),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: thick, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
