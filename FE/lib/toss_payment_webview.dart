// lib/toss_payment_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'api_service.dart';

class TossPaymentWebView extends StatefulWidget {
  final String clientKey;
  final int amount;
  final String orderId;
  final String orderName;
  final void Function(String paymentKey, String orderId, int amount) onSuccess;
  final void Function(String code, String message) onFail;

  const TossPaymentWebView({
    Key? key,
    required this.clientKey,
    required this.amount,
    required this.orderId,
    required this.orderName,
    required this.onSuccess,
    required this.onFail,
  }) : super(key: key);

  @override
  State<TossPaymentWebView> createState() => _TossPaymentWebViewState();
}

class _TossPaymentWebViewState extends State<TossPaymentWebView> {
  late final WebViewController _controller;
  bool _handled = false;

  String get _successUrl => '${ApiService.baseUrl}/payments/toss-success';
  String get _failUrl => '${ApiService.baseUrl}/payments/toss-fail';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _onNavRequest,
        onWebResourceError: (error) {
          if (!_handled && error.errorCode != -1) {
            _handleFail('WEBVIEW_ERROR', error.description);
          }
        },
      ))
      ..loadHtmlString(_buildHtml());
  }

  NavigationDecision _onNavRequest(NavigationRequest req) {
    final url = req.url;

    // 성공 리다이렉트 인터셉트
    if (url.startsWith(_successUrl) || url.contains('/payments/toss-success')) {
      final uri = Uri.tryParse(url);
      final paymentKey = uri?.queryParameters['paymentKey'] ?? '';
      final orderId = uri?.queryParameters['orderId'] ?? '';
      final amount = int.tryParse(uri?.queryParameters['amount'] ?? '0') ?? widget.amount;
      _handleSuccess(paymentKey, orderId, amount);
      return NavigationDecision.prevent;
    }

    // 실패 리다이렉트 인터셉트
    if (url.startsWith(_failUrl) || url.contains('/payments/toss-fail')) {
      final uri = Uri.tryParse(url);
      final code = uri?.queryParameters['code'] ?? 'FAIL';
      final message = uri?.queryParameters['message'] ?? '결제에 실패했습니다.';
      _handleFail(code, message);
      return NavigationDecision.prevent;
    }

    // Android intent:// URL 처리 (TossPay 앱 실행 시도)
    if (url.startsWith('intent://') || url.startsWith('market://')) {
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _handleSuccess(String paymentKey, String orderId, int amount) {
    if (_handled) return;
    _handled = true;
    widget.onSuccess(paymentKey, orderId, amount);
  }

  void _handleFail(String code, String message) {
    if (_handled) return;
    _handled = true;
    widget.onFail(code, message);
  }

  String _buildHtml() {
    final safeOrderName = widget.orderName
        .replaceAll("'", "\\'")
        .replaceAll('"', '\\"');
    final successUrl = _successUrl;
    final failUrl = _failUrl;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #fff; }
    .center {
      display: flex; flex-direction: column; align-items: center;
      justify-content: center; height: 100vh; gap: 16px;
    }
    .spinner {
      width: 40px; height: 40px;
      border: 3px solid #e5e7eb;
      border-top-color: #0064FF;
      border-radius: 50%;
      animation: spin .8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    p { color: #6b7280; font-size: 15px; }
  </style>
</head>
<body>
  <div class="center">
    <div class="spinner"></div>
    <p>토스페이 결제창을 불러오는 중...</p>
  </div>
  <script src="https://js.tosspayments.com/v1/payment-widget"></script>
  <script>
    (function() {
      var clientKey = '${widget.clientKey}';
      var tossPayments = TossPayments(clientKey);
      tossPayments.requestPayment('토스페이', {
        amount: ${widget.amount},
        orderId: '${widget.orderId}',
        orderName: '$safeOrderName',
        successUrl: '$successUrl',
        failUrl: '$failUrl',
        windowTarget: 'self',
      }).catch(function(error) {
        var code = encodeURIComponent(error.code || 'UNKNOWN');
        var msg = encodeURIComponent(error.message || '결제에 실패했습니다.');
        location.href = '$failUrl?code=' + code + '&message=' + msg;
      });
    })();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () {
            _handleFail('USER_CANCEL', '사용자가 결제를 취소했습니다.');
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0064FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text('T',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('토스페이',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
