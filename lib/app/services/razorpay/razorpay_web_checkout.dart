import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Razorpay [Standard Checkout](https://razorpay.com/docs/payments/payment-gateway/web-integration/standard/)
/// in an embedded WebView for desktop (Windows/macOS/Linux) where `razorpay_flutter` has no native SDK.
class RazorpayWebCheckout {
  RazorpayWebCheckout._();

  static Future<void> open({
    required Map<String, dynamic> checkoutOptions,
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onFailure,
  }) async {
    final context = Get.context;
    if (context == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
              maxHeight: 720,
            ),
            child: SizedBox(
              width: 480,
              height: 640,
              child: _RazorpayWebView(
                checkoutOptions: checkoutOptions,
                onSuccess: onSuccess,
                onFailure: onFailure,
                onClose: () => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RazorpayWebView extends StatefulWidget {
  const _RazorpayWebView({
    required this.checkoutOptions,
    required this.onSuccess,
    required this.onFailure,
    required this.onClose,
  });

  final Map<String, dynamic> checkoutOptions;
  final void Function(PaymentSuccessResponse) onSuccess;
  final void Function(PaymentFailureResponse) onFailure;
  final VoidCallback onClose;

  @override
  State<_RazorpayWebView> createState() => _RazorpayWebViewState();
}

class _RazorpayWebViewState extends State<_RazorpayWebView> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'RazorpayFlutter',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJsMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          // Do not set [onNavigationRequest]: webview_win_floating breaks
          // Razorpay's client-side navigation / history.back() when it is set.
        ),
      )
      ..loadHtmlString(_buildHtml(), baseUrl: 'https://checkout.razorpay.com/');
  }

  void _handleJsMessage(String raw) {
    final payload = raw.trim();
    if (payload.isEmpty) {
      // Some desktop WebView implementations can emit empty bridge messages.
      // Ignore safely instead of treating it as a payment failure.
      debugPrint('RazorpayWebCheckout ignored empty JS message');
      return;
    }
    if (!payload.startsWith('{') && !payload.startsWith('[')) {
      // Ignore non-JSON messages coming from webview internals.
      debugPrint('RazorpayWebCheckout ignored non-JSON message: $payload');
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      final type = map['type'] as String?;

      if (type == 'success') {
        final response =
            PaymentSuccessResponse.fromMap(Map<dynamic, dynamic>.from(map));
        widget.onClose();
        widget.onSuccess(response);
        return;
      }
      if (type == 'failed') {
        final err = map['error'];
        int? code;
        if (err is Map) {
          final c = err['code'];
          if (c is int) {
            code = c;
          } else if (c is String) {
            code = int.tryParse(c);
          }
        }
        final fail = PaymentFailureResponse(
          code,
          err is Map ? err['description']?.toString() : err?.toString(),
          err is Map ? Map<dynamic, dynamic>.from(err) : null,
        );
        widget.onClose();
        widget.onFailure(fail);
        return;
      }
      if (type == 'dismissed') {
        widget.onClose();
        widget.onFailure(
          PaymentFailureResponse(
            2,
            'Payment cancelled',
            null,
          ),
        );
        return;
      }
    } catch (e, st) {
      debugPrint('RazorpayWebCheckout parse error: $e\n$st');
      widget.onClose();
      widget.onFailure(
        PaymentFailureResponse(
          0,
          'Payment could not be completed.',
          null,
        ),
      );
    }
  }

  String _buildHtml() {
    final b64 = base64Encode(utf8.encode(jsonEncode(widget.checkoutOptions)));
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #fafafa; }
    #status { padding: 16px; text-align: center; color: #666; font-size: 14px; }
    #actions {
      display: flex;
      justify-content: center;
      padding: 0 16px 16px;
    }
    #payBtn {
      border: none;
      border-radius: 8px;
      background: #3399cc;
      color: #fff;
      padding: 10px 16px;
      font-size: 14px;
      cursor: pointer;
      display: none;
    }
  </style>
</head>
<body>
  <div id="status">Opening Razorpay…</div>
  <div id="actions">
    <button id="payBtn" type="button">Click to continue payment</button>
  </div>
  <script>
    (function () {
      function postToFlutter(payload) {
        if (window.RazorpayFlutter && typeof window.RazorpayFlutter.postMessage === 'function') {
          window.RazorpayFlutter.postMessage(JSON.stringify(payload));
        }
      }
      function decodeBase64Utf8(base64) {
        var binary = atob(base64);
        var bytes = new Uint8Array(binary.length);
        for (var i = 0; i < binary.length; i++) {
          bytes[i] = binary.charCodeAt(i);
        }
        if (typeof TextDecoder !== 'undefined') {
          return new TextDecoder('utf-8').decode(bytes);
        }
        var text = '';
        for (var j = 0; j < bytes.length; j++) {
          text += String.fromCharCode(bytes[j]);
        }
        return decodeURIComponent(escape(text));
      }
      try {
        var statusEl = document.getElementById('status');
        var payBtn = document.getElementById('payBtn');
        var options = JSON.parse(decodeBase64Utf8('$b64'));
        var finished = false;
        var opened = false;
        function finish() { finished = true; }
        function setStatus(text) {
          if (statusEl) statusEl.textContent = text;
        }
        options.handler = function (response) {
          if (finished) return;
          finish();
          postToFlutter({
            type: 'success',
            razorpay_payment_id: response.razorpay_payment_id,
            razorpay_order_id: response.razorpay_order_id,
            razorpay_signature: response.razorpay_signature
          });
        };
        options.modal = options.modal || {};
        var prev = options.modal.ondismiss;
        options.modal.ondismiss = function () {
          if (typeof prev === 'function') prev();
          if (finished) return;
          finish();
          postToFlutter({ type: 'dismissed' });
        };
        var rzp = new Razorpay(options);
        rzp.on('payment.failed', function (response) {
          if (finished) return;
          finish();
          postToFlutter({
            type: 'failed',
            error: response.error
          });
        });
        function openCheckout() {
          if (finished || opened) return;
          try {
            opened = true;
            setStatus('Waiting for Razorpay checkout…');
            rzp.open();
          } catch (e) {
            opened = false;
            setStatus('Click below to continue payment');
            if (payBtn) payBtn.style.display = 'inline-block';
          }
        }
        if (payBtn) {
          payBtn.addEventListener('click', function () {
            openCheckout();
          });
        }
        // Try auto-open first; if desktop WebView blocks it, button allows user gesture retry.
        setTimeout(openCheckout, 0);
      } catch (e) {
        postToFlutter({
          type: 'failed',
          error: { description: String(e) }
        });
      }
    })();
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Secure payment',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.onClose();
                  widget.onFailure(
                    PaymentFailureResponse(2, 'Payment cancelled', null),
                  );
                },
                tooltip: 'Close',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
