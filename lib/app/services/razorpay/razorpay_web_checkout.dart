import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

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

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RazorpayCheckoutPage(
          checkoutOptions: checkoutOptions,
          onSuccess: onSuccess,
          onFailure: onFailure,
        ),
      ),
    );
  }
}

class _RazorpayCheckoutPage extends StatelessWidget {
  const _RazorpayCheckoutPage({
    required this.checkoutOptions,
    required this.onSuccess,
    required this.onFailure,
  });

  final Map<String, dynamic> checkoutOptions;
  final void Function(PaymentSuccessResponse) onSuccess;
  final void Function(PaymentFailureResponse) onFailure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Secure payment',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: _RazorpayWebView(
            checkoutOptions: checkoutOptions,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onClose: () => Navigator.of(context).pop(),
            showHeader: false,
          ),
        ),
      ),
    );
  }
}

class _RazorpayWebView extends StatefulWidget {
  const _RazorpayWebView({
    required this.checkoutOptions,
    required this.onSuccess,
    required this.onFailure,
    required this.onClose,
    this.showHeader = true,
  });

  final Map<String, dynamic> checkoutOptions;
  final void Function(PaymentSuccessResponse) onSuccess;
  final void Function(PaymentFailureResponse) onFailure;
  final VoidCallback onClose;
  final bool showHeader;

  @override
  State<_RazorpayWebView> createState() => _RazorpayWebViewState();
}

class _RazorpayWebViewState extends State<_RazorpayWebView> {
  WebViewController? _controller;
  WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMessageSub;
  StreamSubscription<LoadingState>? _windowsLoadingSub;
  var _loading = true;
  String? _webError;
  bool get _isWindowsDesktop => defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_isWindowsDesktop) {
      _initializeWindowsWebView();
      return;
    }
    _initializeFlutterWebView();
  }

  void _initializeFlutterWebView() {
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
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _webError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _webError = null;
              });
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              'RazorpayWebCheckout web error: ${error.errorCode} ${error.description}',
            );
            if (!mounted) return;
            setState(() {
              _loading = false;
              _webError = 'Secure payment page failed to load.';
            });
          },
          // Keep navigation unrestricted to avoid breaking Razorpay client-side flow.
        ),
      );
    _loadCheckoutHtml();
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      final webViewVersion = await WebviewController.getWebViewVersion();
      if (webViewVersion == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _webError =
              'Microsoft Edge WebView2 Runtime is not installed. Please install it and retry.';
        });
        return;
      }

      final controller = WebviewController();
      await controller.initialize();
      await controller.setBackgroundColor(Colors.white);
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      _windowsMessageSub = controller.webMessage.listen((dynamic message) {
        _handleJsMessage(message?.toString() ?? '');
      });
      _windowsLoadingSub = controller.loadingState.listen((state) {
        if (!mounted) return;
        setState(() {
          _loading = state == LoadingState.loading;
          if (state != LoadingState.loading) {
            _webError = null;
          }
        });
      });
      _windowsController = controller;
      await _loadCheckoutHtml();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _webError =
            'Unable to initialize secure payment view: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _webError = 'Unable to initialize secure payment view.';
      });
      debugPrint('RazorpayWebCheckout windows init error: $e');
    }
  }

  Future<void> _retryCheckout() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _webError = null;
    });
    await _loadCheckoutHtml();
  }

  Future<void> _loadCheckoutHtml() {
    if (_isWindowsDesktop) {
      final controller = _windowsController;
      if (controller == null) return Future.value();
      return controller.loadStringContent(_buildHtml());
    }
    final controller = _controller;
    if (controller == null) return Future.value();
    return controller.loadHtmlString(
      _buildHtml(),
      baseUrl: 'https://checkout.razorpay.com/',
    );
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

      if (type == 'checkout_render_timeout') {
        // Razorpay overlay opened but checkout UI did not render in WebView.
        // Keep user on the same screen and allow retry from the HTML button.
        debugPrint('RazorpayWebCheckout: checkout render timeout, showing retry');
        return;
      }

      if (type == 'success') {
        final response = PaymentSuccessResponse.fromMap(
          Map<dynamic, dynamic>.from(map),
        );
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
        widget.onFailure(PaymentFailureResponse(2, 'Payment cancelled', null));
        return;
      }
    } catch (e, st) {
      debugPrint('RazorpayWebCheckout parse error: $e\n$st');
      widget.onClose();
      widget.onFailure(
        PaymentFailureResponse(0, 'Payment could not be completed.', null),
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
  <meta name="color-scheme" content="light only">
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    html, body { margin: 0; background: #ffffff; }
    body { font-family: system-ui, sans-serif; }
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
          return;
        }
        if (window.chrome && window.chrome.webview && typeof window.chrome.webview.postMessage === 'function') {
          window.chrome.webview.postMessage(JSON.stringify(payload));
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
        var rzp = null;
        var renderWatchdog = null;
        function finish() { finished = true; }
        function setStatus(text) {
          if (statusEl) statusEl.textContent = text;
        }
        function showButton(label) {
          if (!payBtn) return;
          payBtn.textContent = label;
          payBtn.disabled = false;
          payBtn.style.opacity = '1';
          payBtn.style.display = 'inline-block';
        }
        function setButtonBusy(label) {
          if (!payBtn) return;
          payBtn.textContent = label;
          payBtn.disabled = true;
          payBtn.style.opacity = '0.7';
          payBtn.style.display = 'inline-block';
        }
        function hasCheckoutFrame() {
          var frame = document.querySelector('iframe[src*="razorpay"]') ||
            document.querySelector('.razorpay-container iframe') ||
            document.querySelector('.razorpay-checkout-frame');
          if (!frame) return false;
          var rect = frame.getBoundingClientRect();
          var style = window.getComputedStyle(frame);
          var visible = style.display !== 'none' &&
            style.visibility !== 'hidden' &&
            style.opacity !== '0';
          return visible && rect.width > 180 && rect.height > 180;
        }
        function stopWatchdog() {
          if (renderWatchdog) {
            clearTimeout(renderWatchdog);
            renderWatchdog = null;
          }
        }
        function startRenderWatchdog() {
          stopWatchdog();
          renderWatchdog = setTimeout(function () {
            if (finished) return;
            if (hasCheckoutFrame()) return;
            opened = false;
            try { if (rzp) rzp.close(); } catch (_) {}
            rzp = null;
            setStatus('Payment window did not open. Click below to retry.');
            showButton('Continue payment');
            postToFlutter({ type: 'checkout_render_timeout' });
          }, 4500);
        }
        options.handler = function (response) {
          if (finished) return;
          finish();
          stopWatchdog();
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
          stopWatchdog();
          postToFlutter({ type: 'dismissed' });
        };
        function createCheckout() {
          var checkout = new Razorpay(options);
          checkout.on('payment.failed', function (response) {
            if (finished) return;
            finish();
            stopWatchdog();
            postToFlutter({
              type: 'failed',
              error: response.error
            });
          });
          return checkout;
        }
        function openCheckout() {
          if (finished || opened) return;
          try {
            opened = true;
            if (rzp) {
              try { rzp.close(); } catch (_) {}
            }
            rzp = createCheckout();
            setStatus('Waiting for Razorpay checkout…');
            setButtonBusy('Opening...');
            rzp.open();
            startRenderWatchdog();
          } catch (e) {
            opened = false;
            rzp = null;
            setStatus('Click below to continue payment');
            showButton('Continue payment');
          }
        }
        if (payBtn) {
          payBtn.addEventListener('click', function () {
            openCheckout();
          });
        }
        setStatus('Click below to continue payment');
        showButton('Continue payment');
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
    Widget webViewChild;
    if (_isWindowsDesktop) {
      final controller = _windowsController;
      if (controller != null && controller.value.isInitialized) {
        webViewChild = Webview(
          controller,
          permissionRequested: (url, kind, isUserInitiated) async {
            return WebviewPermissionDecision.none;
          },
        );
      } else {
        webViewChild = const SizedBox.expand();
      }
    } else {
      final controller = _controller;
      webViewChild = controller == null
          ? const SizedBox.expand()
          : WebViewWidget(controller: controller);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
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
        if (widget.showHeader) const Divider(height: 1),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: webViewChild,
                ),
              ),
              if (_webError != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _webError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _retryCheckout,
                              child: const Text('Retry payment'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_loading)
                const ColoredBox(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _windowsMessageSub?.cancel();
    _windowsLoadingSub?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }
}
