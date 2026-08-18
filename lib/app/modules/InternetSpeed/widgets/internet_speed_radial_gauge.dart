import 'package:billkaro/app/services/internet_speed/internet_speed_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

/// Semi-circular speedometer. Readout text lives in the parent so layout
/// never fights the gauge canvas.
class InternetSpeedRadialGauge extends StatelessWidget {
  const InternetSpeedRadialGauge({
    super.key,
    required this.value,
    required this.max,
    this.size = 240,
    this.quality = InternetSpeedQuality.unknown,
    this.accentColor,
  });

  final double value;
  final double max;
  final double size;
  final InternetSpeedQuality quality;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? _qualityColor(scheme, quality);
    final displayValue = value.clamp(0, max).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: displayValue),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size * 0.58,
          child: SfRadialGauge(
            enableLoadingAnimation: false,
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: max,
                startAngle: 180,
                endAngle: 0,
                showLabels: false,
                showTicks: false,
                showAxisLine: true,
                canScaleToFit: true,
                radiusFactor: 1,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.16,
                  thicknessUnit: GaugeSizeUnit.factor,
                  color: scheme.onSurface.withValues(alpha: 0.08),
                  cornerStyle: CornerStyle.bothCurve,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: animatedValue,
                    width: 0.16,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: accent,
                    cornerStyle: CornerStyle.bothCurve,
                    enableAnimation: true,
                    animationDuration: 360,
                    animationType: AnimationType.ease,
                  ),
                  NeedlePointer(
                    value: animatedValue,
                    needleColor: scheme.primary,
                    needleStartWidth: 1,
                    needleEndWidth: 5,
                    needleLength: 0.72,
                    lengthUnit: GaugeSizeUnit.factor,
                    knobStyle: KnobStyle(
                      knobRadius: 0.09,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: scheme.primary,
                      borderColor: scheme.surface,
                      borderWidth: 0.02,
                    ),
                    enableAnimation: true,
                    animationDuration: 360,
                    animationType: AnimationType.ease,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _qualityColor(ColorScheme scheme, InternetSpeedQuality quality) {
    switch (quality) {
      case InternetSpeedQuality.excellent:
        return AppColor.success;
      case InternetSpeedQuality.good:
        return AppColor.teal;
      case InternetSpeedQuality.fair:
        return AppColor.warning;
      case InternetSpeedQuality.poor:
        return AppColor.error;
      case InternetSpeedQuality.unknown:
        return scheme.primary;
    }
  }
}
