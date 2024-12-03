import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'classifier.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Offset?> points = [];
  int? recognizedDigit;
  final FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digit Recognizer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildDrawingArea(),
          if (recognizedDigit != null)
            Text(
              '$recognizedDigit',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearCanvas,
        child: const Icon(Icons.clear),
      ),
    );
  }

  Widget _buildDrawingArea() {
    return Container(
      height: 400,
      width: 400,
      color: Colors.black12,
      child: GestureDetector(
        onPanUpdate: (details) {
          final localPosition = details.localPosition;
          if (localPosition.dx >= 0 &&
              localPosition.dx <= 400 &&
              localPosition.dy >= 0 &&
              localPosition.dy <= 400) {
            setState(() => points.add(localPosition));
          }
        },
        onPanEnd: (_) async {
          final classifier = Classifier();
          final digit = await classifier.classifyDrawing(points);
          flutterTts.speak('$digit');
          setState(() => recognizedDigit = digit);
          points.add(null);
        },
        child: CustomPaint(painter: DrawingPainter(points: points)),
      ),
    );
  }

  void _clearCanvas() {
    setState(() {
      points.clear();
      recognizedDigit = null;
    });
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
