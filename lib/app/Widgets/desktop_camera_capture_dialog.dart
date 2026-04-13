import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Opens a dialog to capture a photo using a system camera (built-in or USB).
/// Returns the saved image file path, or `null` if cancelled / error.
Future<String?> showDesktopCameraCaptureDialog() {
  return Get.dialog<String>(
    const DesktopCameraCaptureDialog(),
    barrierDismissible: false,
  );
}

class DesktopCameraCaptureDialog extends StatefulWidget {
  const DesktopCameraCaptureDialog({super.key});

  @override
  State<DesktopCameraCaptureDialog> createState() =>
      _DesktopCameraCaptureDialogState();
}

class _DesktopCameraCaptureDialogState extends State<DesktopCameraCaptureDialog> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedIndex = 0;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      final list = await availableCameras();
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _error =
              'No camera found. Connect a USB webcam or document camera, then try again.';
          _initializing = false;
        });
        return;
      }
      setState(() => _cameras = list);
      await _openCamera(0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not access cameras: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _openCamera(int index) async {
    if (_cameras.isEmpty || index < 0 || index >= _cameras.length) return;

    setState(() {
      _initializing = true;
      _error = null;
    });

    await _controller?.dispose();
    _controller = null;

    final next = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() {
        _controller = next;
        _selectedIndex = index;
        _initializing = false;
      });
    } catch (e) {
      await next.dispose();
      if (!mounted) return;
      setState(() {
        _error = 'Could not start this camera. Try another device in the list.';
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      final shot = await c.takePicture();
      if (!mounted) return;
      Get.back(result: shot.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  String _cameraLabel(int i) {
    final d = _cameras[i];
    final name = d.name.trim();
    if (name.isNotEmpty) return name;
    return 'Camera ${i + 1}';
  }

  bool get _canCapture {
    final c = _controller;
    return !_initializing && c != null && c.value.isInitialized;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Capture from camera',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (_cameras.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<int>(
                    value: _selectedIndex.clamp(0, _cameras.length - 1),
                    decoration: const InputDecoration(
                      labelText: 'Camera device',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (var i = 0; i < _cameras.length; i++)
                        DropdownMenuItem(value: i, child: Text(_cameraLabel(i))),
                    ],
                    onChanged: _initializing
                        ? null
                        : (i) {
                            if (i != null && i != _selectedIndex) {
                              _openCamera(i);
                            }
                          },
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildPreview(theme),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _canCapture ? _capture : null,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Use photo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ),
      );
    }
    if (_initializing || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final c = _controller!;
    final ratio = c.value.aspectRatio;
    if (ratio > 0) {
      return Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: CameraPreview(c),
        ),
      );
    }
    return Center(child: CameraPreview(c));
  }
}
