import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class AnalyticsDonutChart extends StatelessWidget {
  const AnalyticsDonutChart({
    super.key,
    required this.title,
    required this.amount,
    required this.values,
    required this.colors,
  });

  final String title;
  final double amount;
  final List<double> values;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final formattedAmount = CurrencyFormatter.format(amount);
      return Semantics(
        label: '$title, $formattedAmount',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dimension = math.min(constraints.maxWidth, 240.0);
            return SizedBox.square(
              dimension: dimension,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DonutPainter(values: values, colors: colors),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(dimension * 0.19),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 7),
                        ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: dimension * 0.62),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formattedAmount,
                              maxLines: 1,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = math.min(size.width * 0.105, 38.0);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final trackPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);
    if (total <= 0 || colors.isEmpty) return;

    var startAngle = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final value = values[index];
      if (value <= 0) continue;

      final sweep = value / total * math.pi * 2;
      final visibleGap = math.max(0.045, 8 / radius);
      final gap = math.min(visibleGap, sweep * 0.35);
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        math.max(0.0, sweep - gap),
        false,
        Paint()
          ..color = colors[index % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth = strokeWidth,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.colors.length != colors.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      if (oldDelegate.values[index] != values[index]) return true;
    }
    for (var index = 0; index < colors.length; index++) {
      if (oldDelegate.colors[index] != colors[index]) return true;
    }
    return false;
  }
}
