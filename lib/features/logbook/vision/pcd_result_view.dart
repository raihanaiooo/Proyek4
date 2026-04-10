import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_processor.dart';

class PcdResultView extends StatefulWidget {
  final String imagePath;
  const PcdResultView({super.key, required this.imagePath});

  @override
  State<PcdResultView> createState() => _PcdResultViewState();
}

class _PcdResultViewState extends State<PcdResultView> {
  Map<String, Uint8List>? _results;
  bool _isLoading = true;

  final Map<String, String> _labels = {
    'original': 'Original',
    'grayscale': 'Grayscale',
    'contrast': 'Contrast Enhancement',
    'histogram_eq': 'Histogram Equalization',
    'convolution_sharpen': 'Konvolusi — Sharpen',
    'convolution_edge': 'Konvolusi — Edge Detection',
    'noise_reduce': 'Median Filter (Noise Reduction)',
  };

  @override
  void initState() {
    super.initState();
    _process();
  }

  Future<void> _process() async {
    final results = await ImageProcessor.processAll(widget.imagePath);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Pengolahan PCD')),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses citra...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _labels.entries.map((entry) {
                final bytes = _results![entry.key];
                if (bytes == null) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
