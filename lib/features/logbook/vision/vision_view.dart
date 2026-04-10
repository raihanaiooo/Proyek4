import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'vision_controller.dart';
import 'damage_painter.dart';

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
  }

  Widget _buildVisionStack() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Camera Preview
        Center(
          child: AspectRatio(
            aspectRatio: _visionController.controller!.value.aspectRatio,
            child: CameraPreview(_visionController.controller!),
          ),
        ),

        // Layer 2: Overlay hasil deteksi
        Positioned.fill(
          child: CustomPaint(
            painter: DamagePainter(_visionController.currentResults),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart-Patrol Vision")),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (_visionController.errorMessage != null) {
            return Center(child: Text(_visionController.errorMessage!));
          }

          if (!_visionController.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildVisionStack();
        },
      ),
    );
  }

  @override
  void dispose() {
    _visionController.dispose();
    super.dispose();
  }
}
