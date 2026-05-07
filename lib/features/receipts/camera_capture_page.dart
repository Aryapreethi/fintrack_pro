import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/utils/haptics.dart';
import 'thumbnail_service.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  static Future<String?> show(BuildContext context) async {
    return Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCapturePage()),
    );
  }

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  FlashMode _flash = FlashMode.off;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras available on this device.');
        return;
      }
      await _initController(_cameras[_cameraIndex]);
    } catch (e) {
      setState(() => _error = 'Camera unavailable: $e');
    }
  }

  Future<void> _initController(CameraDescription cam) async {
    final controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    await controller.setFlashMode(_flash);
    setState(() => _controller = controller);
  }

  Future<void> _toggleFlash() async {
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };
    setState(() => _flash = next);
    await _controller?.setFlashMode(next);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    setState(() => _cameraIndex = next);
    await _controller?.dispose();
    await _initController(_cameras[next]);
  }

  Future<void> _capture() async {
    if (_controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      await Haptics.success();
      final shot = await _controller!.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      final path = await ThumbnailService().saveCompressed(bytes);
      // Best-effort delete of the temp file from camera plugin.
      try {
        await File(shot.path).delete();
      } catch (_) {}
      if (mounted && path != null) {
        Navigator.of(context).pop(path);
      } else {
        setState(() {
          _busy = false;
          _error = 'Could not save image.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) _initController(_cameras[_cameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  IconData _flashIcon() {
    return switch (_flash) {
      FlashMode.off => Icons.flash_off,
      FlashMode.auto => Icons.flash_auto,
      FlashMode.always => Icons.flash_on,
      FlashMode.torch => Icons.highlight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(_flashIcon(), color: Colors.white),
          ),
          if (_cameras.length > 1)
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _controller == null || !_controller!.value.isInitialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    const _CropGuideOverlay(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: GestureDetector(
                          onTap: _capture,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: _busy ? 60 : 76,
                            height: _busy ? 60 : 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: _busy ? 0.5 : 1.0,
                              ),
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CropGuideOverlay extends StatelessWidget {
  const _CropGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _CropGuidePainter()),
    );
  }
}

class _CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cardWidth = size.width * 0.84;
    final cardHeight = cardWidth * 1.4;
    final left = (size.width - cardWidth) / 2;
    final top = (size.height - cardHeight) / 2;
    final rect = Rect.fromLTWH(left, top, cardWidth, cardHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, scrim);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, stroke);

    // Corner brackets
    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const cornerLen = 24.0;
    void drawCorner(Offset o, Offset hDir, Offset vDir) {
      canvas.drawLine(o, o + hDir * cornerLen, corner);
      canvas.drawLine(o, o + vDir * cornerLen, corner);
    }

    drawCorner(rect.topLeft, const Offset(1, 0), const Offset(0, 1));
    drawCorner(rect.topRight, const Offset(-1, 0), const Offset(0, 1));
    drawCorner(rect.bottomLeft, const Offset(1, 0), const Offset(0, -1));
    drawCorner(rect.bottomRight, const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(covariant _CropGuidePainter oldDelegate) => false;
}
