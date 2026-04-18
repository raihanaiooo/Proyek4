import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'detection_result.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;

  bool isInitialized = false;
  bool isFlashlightOn = false;
  bool isOverlayVisible = true;
  String? errorMessage;

  List<DetectionResult> currentDetections = [];
  Timer? _mockDetectionTimer;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    isInitialized = false;
    errorMessage = null;
    notifyListeners();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage = "No camera detected on device.";
        notifyListeners();
        return;
      }

      controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller!.initialize();
      if (controller != null && controller!.value.isInitialized) {
        isInitialized = true;
        errorMessage = null;
      }
    } catch (e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            errorMessage = "Akses kamera ditolak. Silakan buka pengaturan.";
            break;
          default:
            errorMessage = "Kamera error: ${e.description}";
        }
      } else {
        errorMessage = "Gagal memuat kamera: $e";
      }
      isInitialized = false;
    }
    notifyListeners();
  }

  Future<XFile?> takePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return null;
    try {
      await controller!.pausePreview();
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await controller!.takePicture();
      await controller!.resumePreview();
      return image;
    } catch (e) {
      errorMessage = "Failed to capture photo: $e";
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleFlashlight() async {
    if (controller == null || !controller!.value.isInitialized) return;
    isFlashlightOn = !isFlashlightOn;
    try {
      await controller!.setFlashMode(
        isFlashlightOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      errorMessage = "Failed to toggle flashlight: $e";
    }
    notifyListeners();
  }

  void toggleOverlay() {
    isOverlayVisible = !isOverlayVisible;
    notifyListeners();
  }

  void startMockDetection() {
    _mockDetectionTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => _generateMockDetection(),
    );
  }

  void _generateMockDetection() {
    if (!isInitialized) return;
    final random = Random();
    if (random.nextDouble() < 0.2) {
      currentDetections = [];
    } else {
      final x = random.nextDouble() * 0.6 + 0.1;
      final y = random.nextDouble() * 0.6 + 0.1;

      currentDetections = [
        DetectionResult(
          box: Rect.fromLTWH(x, y, 0.3, 0.2),
          label: _getRandomDamageType(),
          score: 0.7 + random.nextDouble() * 0.29,
        ),
      ];
    }
    notifyListeners();
  }

  String _getRandomDamageType() {
    final types = ['D00', 'D10', 'D20', 'D40'];
    final labels = {
      'D00': 'Longitudinal Crack',
      'D10': 'Transverse Crack',
      'D20': 'Alligator Crack',
      'D40': 'Pothole',
    };
    final type = types[Random().nextInt(types.length)];
    return '$type - ${labels[type]}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized)
      return;

    if (state == AppLifecycleState.inactive) {
      isInitialized = false;
      cameraController.dispose();
      controller = null;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mockDetectionTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }
}
