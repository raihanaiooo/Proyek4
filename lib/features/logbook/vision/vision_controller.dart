import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'detection_result.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  bool isProcessing = false;
  String? errorMessage;
  List<DetectionResult> _currentResults = [];

  List<DetectionResult> get currentResults => _currentResults;

  VisionController() {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
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
      );

      await controller!.initialize();
      isInitialized = true;
      errorMessage = null;
    } catch (e) {
      errorMessage = "Failed to initialize camera: $e";
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      isInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  static Future<List<DetectionResult>> heavyInferenceTask(
    CameraImage image,
  ) async {
    // Placeholder untuk inferensi model AI
    return [];
  }

  void processFrame(CameraImage image) async {
    if (isProcessing) return;

    isProcessing = true;
    final results = await compute(heavyInferenceTask, image);
    _currentResults = results;
    notifyListeners();
    isProcessing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }
}
