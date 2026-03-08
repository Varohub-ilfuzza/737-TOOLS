import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/annotations_service.dart';

class AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> strokes;
  final AnnotationStroke? currentStroke;

  const AnnotationPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, AnnotationStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (stroke.tool) {
      case DrawingTool.pen:
        _drawPen(canvas, paint, stroke.points);
        break;
      case DrawingTool.arrow:
        if (stroke.points.length >= 2) {
          _drawArrow(canvas, paint, stroke.points.first, stroke.points.last);
        }
        break;
    }
  }

  void _drawPen(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length == 1) {
      canvas.drawCircle(
        points.first,
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      // Smooth curve through midpoints
      if (i < points.length - 1) {
        final mid = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(
            points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    canvas.drawLine(start, end, paint);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 4) return;

    final angle = math.atan2(dy, dx);
    final arrowLen = math.max(16.0, paint.strokeWidth * 5).clamp(16.0, 40.0);
    const arrowAngle = math.pi / 6;

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowLen * math.cos(angle - arrowAngle),
        end.dy - arrowLen * math.sin(angle - arrowAngle),
      )
      ..lineTo(
        end.dx - arrowLen * math.cos(angle + arrowAngle),
        end.dy - arrowLen * math.sin(angle + arrowAngle),
      )
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(AnnotationPainter old) =>
      old.strokes != strokes || old.currentStroke != currentStroke;
}
