import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessor {
  /// Menerapkan semua operasi PCD sekaligus dan mengembalikan map hasilnya
  static Future<Map<String, Uint8List>> processAll(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(bytes)!;

    return {
      'original': Uint8List.fromList(img.encodeJpg(original)),
      'grayscale': Uint8List.fromList(img.encodeJpg(toGrayscale(original))),
      'contrast': Uint8List.fromList(
        img.encodeJpg(adjustContrast(original, factor: 1.8)),
      ),
      'histogram_eq': Uint8List.fromList(
        img.encodeJpg(histogramEqualization(original)),
      ),
      'convolution_sharpen': Uint8List.fromList(
        img.encodeJpg(applySharpen(original)),
      ),
      'convolution_edge': Uint8List.fromList(
        img.encodeJpg(applyEdgeDetection(original)),
      ),
      'noise_reduce': Uint8List.fromList(
        img.encodeJpg(applyMedianFilter(original)),
      ),
    };
  }

  // ===================== GRAYSCALE =====================
  // Rumus: Gray = 0.299R + 0.587G + 0.114B
  static img.Image toGrayscale(img.Image src) {
    final out = img.Image(width: src.width, height: src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final gray = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).toInt().clamp(
          0,
          255,
        );
        out.setPixelRgb(x, y, gray, gray, gray);
      }
    }
    return out;
  }

  // ===================== CONTRAST =====================
  // Rumus: newPixel = clamp((pixel - 128) * factor + 128, 0, 255)
  static img.Image adjustContrast(img.Image src, {double factor = 1.5}) {
    final out = img.Image(width: src.width, height: src.height);
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        int r = ((p.r - 128) * factor + 128).toInt().clamp(0, 255);
        int g = ((p.g - 128) * factor + 128).toInt().clamp(0, 255);
        int b = ((p.b - 128) * factor + 128).toInt().clamp(0, 255);
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }

  // ===================== HISTOGRAM EQUALIZATION =====================
  // Rumus: s_k = (L-1) * CDF(k), diterapkan per channel
  static img.Image histogramEqualization(img.Image src) {
    final gray = toGrayscale(src);
    final out = img.Image(width: src.width, height: src.height);
    final total = src.width * src.height;

    // Hitung histogram
    final hist = List<int>.filled(256, 0);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        hist[gray.getPixel(x, y).r.toInt()]++;
      }
    }

    // Hitung CDF dan buat lookup table
    final lut = List<int>.filled(256, 0);
    int cumulative = 0;
    for (int i = 0; i < 256; i++) {
      cumulative += hist[i];
      lut[i] = ((cumulative / total) * 255).toInt().clamp(0, 255);
    }

    // Terapkan LUT
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final val = lut[gray.getPixel(x, y).r.toInt()];
        out.setPixelRgb(x, y, val, val, val);
      }
    }
    return out;
  }

  // ===================== KONVOLUSI — SHARPEN =====================
  // Kernel: [[0,-1,0],[-1,5,-1],[0,-1,0]]
  static img.Image applySharpen(img.Image src) {
    const kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];
    return _applyKernel(src, kernel);
  }

  // ===================== KONVOLUSI — EDGE DETECTION =====================
  // Kernel: [[-1,-1,-1],[-1,8,-1],[-1,-1,-1]]
  static img.Image applyEdgeDetection(img.Image src) {
    const kernel = [
      [-1, -1, -1],
      [-1, 8, -1],
      [-1, -1, -1],
    ];
    return _applyKernel(toGrayscale(src), kernel);
  }

  // ===================== MEDIAN FILTER (Noise Reduction) =====================
  // Ganti setiap piksel dengan nilai median dari tetangganya (3x3)
  static img.Image applyMedianFilter(img.Image src) {
    final out = img.Image(width: src.width, height: src.height);
    for (int y = 1; y < src.height - 1; y++) {
      for (int x = 1; x < src.width - 1; x++) {
        final reds = <int>[], greens = <int>[], blues = <int>[];
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final p = src.getPixel(x + dx, y + dy);
            reds.add(p.r.toInt());
            greens.add(p.g.toInt());
            blues.add(p.b.toInt());
          }
        }
        reds.sort();
        greens.sort();
        blues.sort();
        out.setPixelRgb(x, y, reds[4], greens[4], blues[4]);
      }
    }
    return out;
  }

  // ===================== HELPER: APPLY KERNEL =====================
  static img.Image _applyKernel(img.Image src, List<List<int>> kernel) {
    final out = img.Image(width: src.width, height: src.height);
    for (int y = 1; y < src.height - 1; y++) {
      for (int x = 1; x < src.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final p = src.getPixel(x + kx - 1, y + ky - 1);
            final k = kernel[ky][kx];
            r += p.r * k;
            g += p.g * k;
            b += p.b * k;
          }
        }
        out.setPixelRgb(
          x,
          y,
          r.toInt().clamp(0, 255),
          g.toInt().clamp(0, 255),
          b.toInt().clamp(0, 255),
        );
      }
    }
    return out;
  }
}
