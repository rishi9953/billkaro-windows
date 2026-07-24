import 'dart:async';

import 'package:billkaro/app/services/remote_barcode/remote_barcode_host_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Starts a LAN host and waits for a barcode from the BillKaro mobile app.
Future<String?> showPhoneBarcodePairDialog() async {
  final host = RemoteBarcodeHostService();
  try {
    await host.start(mode: 'menu');
  } catch (e) {
    await Get.dialog(
      AlertDialog(
        title: const Text('Cannot start phone scanner'),
        content: Text('$e'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
    await host.dispose();
    return null;
  }

  final result = await Get.dialog<String>(
    _PhoneBarcodePairDialog(host: host),
    barrierDismissible: false,
  );
  await host.dispose();
  return result;
}

class _PhoneBarcodePairDialog extends StatefulWidget {
  const _PhoneBarcodePairDialog({required this.host});

  final RemoteBarcodeHostService host;

  @override
  State<_PhoneBarcodePairDialog> createState() =>
      _PhoneBarcodePairDialogState();
}

class _PhoneBarcodePairDialogState extends State<_PhoneBarcodePairDialog> {
  StreamSubscription? _barcodeSub;
  StreamSubscription? _statusSub;
  RemoteBarcodeHostStatus? _status;
  String? _lastCode;

  @override
  void initState() {
    super.initState();
    _status = RemoteBarcodeHostStatus(
      running: true,
      phoneConnected: false,
      lanIp: widget.host.lanIp,
      port: widget.host.port,
      pairingPayload: widget.host.pairingPayload,
    );
    _statusSub = widget.host.status.listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
    });
    _barcodeSub = widget.host.barcodes.listen((code) {
      if (!mounted) return;
      setState(() => _lastCode = code);
      // Auto-accept first scan.
      Get.back(result: code);
    });
  }

  @override
  void dispose() {
    _barcodeSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final payload = status?.pairingPayload ?? '';
    final connected = status?.phoneConnected == true;
    final ip = status?.lanIp ?? '—';
    final port = status?.port ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_android, color: AppColor.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Use phone as scanner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '1. Open BillKaro on your phone → Settings → PC barcode scanner\n'
                '2. Scan this QR (same Wi‑Fi as this PC)\n'
                '3. Point phone camera at the product barcode',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: payload.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: connected
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: connected
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      connected
                          ? Icons.check_circle_outline
                          : Icons.hourglass_top_rounded,
                      color: connected ? Colors.green : Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connected
                            ? 'Phone connected — waiting for a scan…'
                            : 'Waiting for phone to connect…',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: connected
                              ? Colors.green.shade800
                              : Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PC: $ip:$port',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: payload.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: payload),
                            );
                            showSuccess(description: 'Pairing code copied');
                          },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              if (_lastCode != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last scan: $_lastCode',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Phone and PC must be on the same Wi‑Fi. Allow BillKaro through Windows Firewall if asked.',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
