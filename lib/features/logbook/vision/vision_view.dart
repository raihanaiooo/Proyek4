import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pcd_result_view.dart';

class VisionView extends StatefulWidget {
  const VisionView({super.key});

  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;

  @override
  void initState() {
    super.initState();
    _visionController = VisionController();
    _visionController.startMockDetection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.4),
        title: const Text(
          "Smart-Patrol Vision",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ListenableBuilder(
            listenable: _visionController,
            builder: (context, _) => Row(
              children: [
                IconButton(
                  icon: Icon(
                    _visionController.isFlashlightOn
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _visionController.toggleFlashlight,
                  tooltip: 'Toggle Flashlight',
                ),
                IconButton(
                  icon: Icon(
                    _visionController.isOverlayVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: _visionController.toggleOverlay,
                  tooltip: 'Toggle Overlay',
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return _buildLoadingState();
          }
          return _buildVisionStack();
        },
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _visionController,
        builder: (context, _) {
          if (!_visionController.isInitialized) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              final image = await _visionController.takePhoto();
              if (image != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PcdResultView(imagePath: image.path),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Foto tersimpan: ${image.path}'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            tooltip: 'Ambil Foto',
            child: const Icon(Icons.camera_alt, color: Colors.black),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            "Menghubungkan ke Sensor Visual...",
            style: TextStyle(fontSize: 16),
          ),
          if (_visionController.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _visionController.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text("Open Settings"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // LAYER 1: Preview kamera full layar
        SizedBox.expand(child: CameraPreview(_visionController.controller!)),

        // LAYER 2: Overlay deteksi
        if (_visionController.isOverlayVisible)
          Positioned.fill(
            child: CustomPaint(
              painter: DamagePainter(_visionController.currentDetections),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }
}
