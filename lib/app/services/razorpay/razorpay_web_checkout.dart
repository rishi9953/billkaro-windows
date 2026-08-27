import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

/// Opens Razorpay Standard Checkout in a dimmed overlay, the same desktop
/// modal Razorpay shows in a browser (sidebar + payment methods + UPI QR).
class RazorpayWebCheckout {
  RazorpayWebCheckout._();

  static Future<void> open({
    required Map<String, dynamic> checkoutOptions,
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onFailure,
  }) async {
    final context = Get.context;
    if (context == null) return;

    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: const Color(0x99000000),
        pageBuilder: (_, __, ___) => _RazorpayCheckoutPage(
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
    final showWindowsTitleBar = !kIsWeb && Platform.isWindows;
    final checkout = _RazorpayWebView(
      checkoutOptions: checkoutOptions,
      onSuccess: onSuccess,
      onFailure: onFailure,
      onClose: () => Navigator.of(context).pop(),
    );

    if (!showWindowsTitleBar) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: checkout,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const WindowsDesktopTitleBar(actions: []),
          Expanded(child: checkout),
        ],
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
  });

  final Map<String, dynamic> checkoutOptions;
  final void Function(PaymentSuccessResponse) onSuccess;
  final void Function(PaymentFailureResponse) onFailure;
  final VoidCallback onClose;

  @override
  State<_RazorpayWebView> createState() => _RazorpayWebViewState();
}

class _RazorpayWebViewState extends State<_RazorpayWebView> {
  WebViewController? _controller;
  WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMessageSub;
  StreamSubscription<LoadingState>? _windowsLoadingSub;
  StreamSubscription<WebErrorStatus>? _windowsLoadErrorSub;

  var _loading = true;
  var _pageReady = false;
  var _checkoutSettled = false;
  String? _webError;

  bool get _isWindowsDesktop =>
      defaultTargetPlatform == TargetPlatform.windows;

  void _settleSuccess(PaymentSuccessResponse response) {
    if (_checkoutSettled) return;
    _checkoutSettled = true;
    widget.onSuccess(response);
    widget.onClose();
  }

  void _settleFailure(PaymentFailureResponse response) {
    if (_checkoutSettled) return;
    _checkoutSettled = true;
    widget.onFailure(response);
    widget.onClose();
  }

  void _cancel() {
    _settleFailure(PaymentFailureResponse(2, 'Payment cancelled', null));
  }

  @override
  void initState() {
    super.initState();
    if (_isWindowsDesktop) {
      _initializeWindowsWebView();
    } else {
      _initializeFlutterWebView();
    }
  }

  void _initializeFlutterWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'RazorpayFlutter',
        onMessageReceived: (message) => _handleJsMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _webError = null;
            });
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
        ),
      );
    _loadCheckoutHtml();
  }

  Future<void> _initializeWindowsWebView() async {
    try {
      final version = await WebviewController.getWebViewVersion();
      if (version == null) {
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
      await controller.setBackgroundColor(Colors.transparent);
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.allow);
      await controller.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      );

      _windowsMessageSub = controller.webMessage.listen((dynamic message) {
        _handleJsMessage(message?.toString() ?? '');
      });
      _windowsLoadErrorSub = controller.onLoadError.listen((status) {
        debugPrint('RazorpayWebCheckout load error: $status');
        if (!mounted || _pageReady) return;
        setState(() {
          _loading = false;
          _webError = 'Secure payment page failed to load.';
        });
      });
      _windowsLoadingSub = controller.loadingState.listen((state) {
        if (!mounted) return;
        if (state == LoadingState.navigationCompleted) {
          setState(() {
            _pageReady = true;
            _loading = false;
            _webError = null;
          });
        } else if (!_pageReady) {
          setState(() => _loading = state == LoadingState.loading);
        }
      });

      _windowsController = controller;
      if (mounted) setState(() {});
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
      _loading = !_pageReady;
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
    if (payload.isEmpty ||
        (!payload.startsWith('{') && !payload.startsWith('['))) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);

      switch (map['type']) {
        case 'ready':
          if (mounted) setState(() => _loading = false);
          return;
        case 'success':
          _settleSuccess(
            PaymentSuccessResponse.fromMap(Map<dynamic, dynamic>.from(map)),
          );
          return;
        case 'failed':
          final err = map['error'];
          int? code;
          if (err is Map) {
            final value = err['code'];
            if (value is int) code = value;
            if (value is String) code = int.tryParse(value);
          }
          _settleFailure(
            PaymentFailureResponse(
              code,
              err is Map ? err['description']?.toString() : err?.toString(),
              err is Map ? Map<dynamic, dynamic>.from(err) : null,
            ),
          );
          return;
        case 'dismissed':
          Future<void>.delayed(const Duration(milliseconds: 500), () {
            if (_checkoutSettled || !mounted) return;
            _settleFailure(
              PaymentFailureResponse(2, 'Payment cancelled', null),
            );
          });
          return;
      }
    } catch (e, st) {
      debugPrint('RazorpayWebCheckout parse error: $e\n$st');
      _settleFailure(
        PaymentFailureResponse(0, 'Payment could not be completed.', null),
      );
    }
  }

  String _buildHtml() {
    final optionsB64 = base64Encode(utf8.encode(jsonEncode(widget.checkoutOptions)));
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <base href="https://checkout.razorpay.com/">
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: transparent;
      font-family: system-ui, sans-serif;
    }
    .razorpay-container,
    .razorpay-backdrop {
      background: transparent !important;
    }
    #retry {
      display: none;
      position: absolute;
      left: 50%;
      top: 50%;
      transform: translate(-50%, -50%);
      border: 0;
      border-radius: 8px;
      background: #12B3A3;
      color: #fff;
      padding: 12px 20px;
      font-size: 14px;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <button id="retry" type="button">Continue payment</button>
  <script>
    (function () {
      function post(payload) {
        var data = JSON.stringify(payload);
        if (window.RazorpayFlutter && window.RazorpayFlutter.postMessage) {
          window.RazorpayFlutter.postMessage(data);
          return;
        }
        if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
          window.chrome.webview.postMessage(data);
        }
      }

      function decodeOptions(b64) {
        var binary = atob(b64);
        var bytes = new Uint8Array(binary.length);
        for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
        return JSON.parse(new TextDecoder('utf-8').decode(bytes));
      }

      var finished = false;
      var retryBtn = document.getElementById('retry');
      var options = decodeOptions('$optionsB64');

      options.handler = function (response) {
        if (finished) return;
        finished = true;
        post({
          type: 'success',
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_order_id: response.razorpay_order_id,
          razorpay_signature: response.razorpay_signature
        });
      };

      options.modal = options.modal || {};
      options.modal.ondismiss = function () {
        setTimeout(function () {
          if (finished) return;
          finished = true;
          post({ type: 'dismissed' });
        }, 400);
      };

      function openCheckout() {
        if (finished || typeof Razorpay === 'undefined') {
          retryBtn.style.display = 'block';
          return;
        }
        retryBtn.style.display = 'none';
        var checkout = new Razorpay(options);
        checkout.on('payment.failed', function (response) {
          if (finished) return;
          finished = true;
          post({ type: 'failed', error: response.error });
        });
        post({ type: 'ready' });
        checkout.open();
        var style = document.createElement('style');
        style.textContent =
          'html,body,.razorpay-container,.razorpay-backdrop{background:transparent!important;}';
        document.head.appendChild(style);
      }

      retryBtn.addEventListener('click', openCheckout);

      var tries = 40;
      (function waitForScript() {
        if (typeof Razorpay !== 'undefined') {
          openCheckout();
          return;
        }
        if (tries-- <= 0) {
          retryBtn.style.display = 'block';
          return;
        }
        setTimeout(waitForScript, 250);
      })();
    })();
  </script>
</body>
</html>
''';
  }

  Widget _buildWebView() {
    if (_isWindowsDesktop) {
      final controller = _windowsController;
      if (controller == null || !controller.value.isInitialized) {
        return const SizedBox.expand();
      }
      return Webview(
        controller,
        permissionRequested: (url, kind, isUserInitiated) async {
          return WebviewPermissionDecision.none;
        },
      );
    }
    final controller = _controller;
    if (controller == null) return const SizedBox.expand();
    return WebViewWidget(controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final webWidth = (size.width - 72).clamp(640.0, 1040.0);
    final webHeight = (size.height - 100).clamp(480.0, 680.0);

    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: webWidth,
            height: webHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildWebView(),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            tooltip: 'Close',
            color: Colors.white,
            onPressed: _cancel,
            icon: const Icon(Icons.close, size: 28),
          ),
        ),
        if (_webError != null)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        _webError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
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
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  @override
  void dispose() {
    _windowsMessageSub?.cancel();
    _windowsLoadingSub?.cancel();
    _windowsLoadErrorSub?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }
}
