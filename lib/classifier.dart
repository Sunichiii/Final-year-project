import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tf;
import 'dart:ui' as ui;
import 'dart:math';

import 'assets.dart';

class Classifier {
  Classifier();

  Future<int> classifyDrawing(List<Offset?> points) async {
    final picture = _convertPointsToPicture(points);
    final image = await picture.toImage(28, 28);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final imageAsList = byteData?.buffer.asUint8List();

    if (imageAsList == null) throw Exception("Failed to convert image.");

    return _runModel(imageAsList);
  }

  Future<int> _runModel(Uint8List imageAsList) async {
    List<double> grayscale = _convertToGrayscale(imageAsList);

    // Log the grayscale input
    debugPrint('Grayscale input: $grayscale');

    final input = grayscale.reshape([1, 28, 28, 1]); // Reshaping for the model
    final output = List.filled(10, 0.0).reshape([1, 10]);

    try {
      final interpreter = await tf.Interpreter.fromAsset(Assets.modelPath);
      interpreter.run(input, output);

      // Log the output for debugging
      debugPrint('Model output: ${output[0]}');
    } catch (e) {
      debugPrint('Error running model: $e');
    }

    return _getPredictedDigit(output[0]);
  }

  List<double> _convertToGrayscale(Uint8List imageAsList) {
    List<double> grayscale = List.filled(28 * 28, 0.0);

    // Convert the image from raw RGBA to grayscale (0 to 255 scale)
    for (int i = 0, j = 0; i < imageAsList.length; i += 4, j++) {
      final avg = (imageAsList[i] + imageAsList[i + 1] + imageAsList[i + 2]) / 3;
      grayscale[j] = avg; // Store grayscale value in range [0, 255]
    }

    // Normalize grayscale values to the range [0, 1] as expected by the model
    grayscale = grayscale.map((value) => value / 255.0).toList();

    // Debugging grayscale values to check if the conversion is correct
    debugPrint('Sample grayscale values: ${grayscale.take(10)}');

    return grayscale;
  }

  int _getPredictedDigit(List<double> output) {
    int digit = 0;
    double highestProb = 0.0;

    // Find the highest probability index in the output list
    for (int i = 0; i < output.length; i++) {
      if (output[i] > highestProb) {
        highestProb = output[i];
        digit = i;
      }
    }

    debugPrint('Predicted digit: $digit');
    return digit;
  }

  ui.Picture _convertPointsToPicture(List<Offset?> points) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 28, 28));

    // Background should be black (0xFF000000)
    final bgPaint = Paint()..color = const Color(0xFF000000);  // Black background
    canvas.drawRect(const Rect.fromLTWH(0, 0, 28, 28), bgPaint);

    // Drawing color should be white (0xFFFFFFFF)
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFFFFF) // White for the drawing
      ..strokeWidth = 12;

    // Scale the points to fit them within the 28x28 canvas size
    final scaleFactor = _getScaleFactor(points);

    // Draw the points on the canvas
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final scaledStart = Offset(points[i]!.dx * scaleFactor, points[i]!.dy * scaleFactor);
        final scaledEnd = Offset(points[i + 1]!.dx * scaleFactor, points[i + 1]!.dy * scaleFactor);
        canvas.drawLine(scaledStart, scaledEnd, paint);
      }
    }

    return recorder.endRecording();
  }

  double _getScaleFactor(List<Offset?> points) {
    double maxX = 0.0;
    double maxY = 0.0;

    // Find the maximum x and y values to determine the scale
    for (var point in points) {
      if (point != null) {
        maxX = max(maxX, point.dx);
        maxY = max(maxY, point.dy);
      }
    }

    // The scale factor ensures that the points fit within the 28x28 canvas size
    return max(maxX, maxY) > 0.0 ? 28.0 / max(maxX, maxY) : 1.0;
  }
}
