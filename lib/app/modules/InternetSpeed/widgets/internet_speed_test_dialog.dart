import 'dart:async';

import 'package:billkaro/app/Widgets/custom_button.dart';
import 'package:billkaro/app/modules/InternetSpeed/internet_speed_controller.dart';
import 'package:billkaro/app/modules/InternetSpeed/widgets/internet_speed_radial_gauge.dart';
import 'package:billkaro/app/services/internet_speed/internet_speed_models.dart';
import 'package:billkaro/config/config.dart';

Future<void> showInternetSpeedTestDialog(BuildContext context) {
  final controller = InternetSpeedController.ensure();

  final dialog = showDialog<void>(
    context: context,
    builder: (_) => const InternetSpeedTestDialog(),
  );

  if (controller.phase.value == InternetSpeedPhase.idle) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.startTest());
    });
  }

  return dialog;
}

class InternetSpeedTestDialog extends StatelessWidget {
  const InternetSpeedTestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 420 : 380,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Obx(() {
          final controller = InternetSpeedController.ensure();
          final snapshot = _SpeedSnapshot.from(controller);
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: SingleChildScrollView(
              key: ValueKey('${snapshot.phase.name}-${snapshot.error.name}'),
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(loc: loc, scheme: scheme),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      loc.internet_speed_test_subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.58),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PhaseStepper(phase: snapshot.phase, loc: loc, scheme: scheme),
                  const SizedBox(height: 8),
                  _HeroReadout(snapshot: snapshot, loc: loc, scheme: scheme),
                  const SizedBox(height: 20),
                  _MetricsRow(snapshot: snapshot, loc: loc, scheme: scheme),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CustomButton(
                      text: _buttonLabel(snapshot.phase, loc),
                      onPressed: controller.startTest,
                      isLoading: snapshot.isRunning,
                      width: double.infinity,
                      icon: snapshot.isRunning
                          ? null
                          : snapshot.phase == InternetSpeedPhase.completed
                          ? Icons.refresh_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _buttonLabel(InternetSpeedPhase phase, AppLocalizations loc) {
    if (phase == InternetSpeedPhase.completed ||
        phase == InternetSpeedPhase.failed) {
      return loc.internet_speed_retest;
    }
    if (phase == InternetSpeedPhase.idle) return loc.internet_speed_start_test;
    return loc.internet_speed_testing;
  }
}

class _SpeedSnapshot {
  const _SpeedSnapshot({
    required this.phase,
    required this.pingMs,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.liveMbps,
    required this.error,
    required this.isRunning,
  });

  factory _SpeedSnapshot.from(InternetSpeedController controller) {
    return _SpeedSnapshot(
      phase: controller.phase.value,
      pingMs: controller.pingMs.value,
      downloadMbps: controller.downloadMbps.value,
      uploadMbps: controller.uploadMbps.value,
      liveMbps: controller.liveMbps.value,
      error: controller.error.value,
      isRunning: controller.isRunning,
    );
  }

  final InternetSpeedPhase phase;
  final double pingMs;
  final double downloadMbps;
  final double uploadMbps;
  final double liveMbps;
  final InternetSpeedError error;
  final bool isRunning;

  InternetSpeedQuality get quality =>
      InternetSpeedQualityX.fromDownloadMbps(downloadMbps);

  double get primaryValue {
    switch (phase) {
      case InternetSpeedPhase.ping:
        return pingMs;
      case InternetSpeedPhase.download:
      case InternetSpeedPhase.upload:
        return liveMbps;
      case InternetSpeedPhase.completed:
      case InternetSpeedPhase.failed:
      case InternetSpeedPhase.idle:
        return downloadMbps;
    }
  }

  double get uploadDisplay =>
      phase == InternetSpeedPhase.upload ? liveMbps : uploadMbps;
}

class _Header extends StatelessWidget {
  const _Header({required this.loc, required this.scheme});

  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.speed_rounded, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            loc.internet_speed_test,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(context).pop(),
          tooltip: loc.close,
          icon: Icon(
            Icons.close_rounded,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _PhaseStepper extends StatelessWidget {
  const _PhaseStepper({
    required this.phase,
    required this.loc,
    required this.scheme,
  });

  final InternetSpeedPhase phase;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final pingDone =
        phase == InternetSpeedPhase.download ||
        phase == InternetSpeedPhase.upload ||
        phase == InternetSpeedPhase.completed;
    final downDone =
        phase == InternetSpeedPhase.upload ||
        phase == InternetSpeedPhase.completed;
    final upDone = phase == InternetSpeedPhase.completed;

    return Row(
      children: [
        _Step(
          label: loc.internet_speed_ping,
          active: phase == InternetSpeedPhase.ping,
          done: pingDone,
          scheme: scheme,
        ),
        _StepLine(filled: pingDone, scheme: scheme),
        _Step(
          label: loc.internet_speed_download,
          active: phase == InternetSpeedPhase.download,
          done: downDone,
          scheme: scheme,
        ),
        _StepLine(filled: downDone, scheme: scheme),
        _Step(
          label: loc.internet_speed_upload,
          active: phase == InternetSpeedPhase.upload,
          done: upDone,
          scheme: scheme,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.active,
    required this.done,
    required this.scheme,
  });

  final String label;
  final bool active;
  final bool done;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final color = done || active
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.28);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? scheme.primary : Colors.transparent,
            border: Border.all(color: color, width: 1.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active || done ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.filled, required this.scheme});

  final bool filled;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 1.5,
          color: filled
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _HeroReadout extends StatelessWidget {
  const _HeroReadout({
    required this.snapshot,
    required this.loc,
    required this.scheme,
  });

  final _SpeedSnapshot snapshot;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isPing = snapshot.phase == InternetSpeedPhase.ping;
    final quality = isPing
        ? InternetSpeedQualityX.fromPingMs(snapshot.pingMs)
        : snapshot.quality;
    final accent = _accentFor(scheme, quality, snapshot.phase);
    final unit = isPing ? loc.internet_speed_ms : loc.internet_speed_mbps;
    final label = switch (snapshot.phase) {
      InternetSpeedPhase.ping => loc.internet_speed_ping,
      InternetSpeedPhase.upload => loc.internet_speed_upload,
      _ => loc.internet_speed_download,
    };

    return Column(
      children: [
        InternetSpeedRadialGauge(
          value: snapshot.primaryValue,
          max: isPing ? 300 : 150,
          quality: quality,
          accentColor: accent,
        ),
        const SizedBox(height: 4),
        _AnimatedNumberText(
          value: snapshot.primaryValue,
          decimals: isPing ? 0 : (snapshot.primaryValue < 10 ? 1 : 1),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.8,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            '$unit  ·  $label',
            key: ValueKey('$unit-$label'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _StatusLine(snapshot: snapshot, loc: loc, scheme: scheme),
      ],
    );
  }

  Color _accentFor(
    ColorScheme scheme,
    InternetSpeedQuality quality,
    InternetSpeedPhase phase,
  ) {
    if (phase != InternetSpeedPhase.completed) return scheme.primary;
    return switch (quality) {
      InternetSpeedQuality.excellent => AppColor.success,
      InternetSpeedQuality.good => AppColor.teal,
      InternetSpeedQuality.fair => AppColor.warning,
      InternetSpeedQuality.poor => AppColor.error,
      InternetSpeedQuality.unknown => scheme.primary,
    };
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.snapshot,
    required this.loc,
    required this.scheme,
  });

  final _SpeedSnapshot snapshot;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final failed = snapshot.error != InternetSpeedError.none;
    final done = snapshot.phase == InternetSpeedPhase.completed;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            _message(),
            key: ValueKey(_message()),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: failed
                  ? AppColor.error
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        if (done) ...[
          const SizedBox(height: 8),
          AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: 1,
            child: _QualityChip(quality: snapshot.quality, loc: loc),
          ),
        ],
      ],
    );
  }

  String _message() {
    switch (snapshot.error) {
      case InternetSpeedError.offline:
        return loc.internet_speed_offline;
      case InternetSpeedError.failed:
        return loc.internet_speed_failed;
      case InternetSpeedError.none:
        break;
    }
    switch (snapshot.phase) {
      case InternetSpeedPhase.idle:
        return loc.internet_speed_idle_hint;
      case InternetSpeedPhase.ping:
        return loc.internet_speed_phase_ping;
      case InternetSpeedPhase.download:
        return loc.internet_speed_phase_download;
      case InternetSpeedPhase.upload:
        return loc.internet_speed_phase_upload;
      case InternetSpeedPhase.completed:
        return '${loc.internet_speed_download} ${formatSpeedMbps(snapshot.downloadMbps)} ${loc.internet_speed_mbps}';
      case InternetSpeedPhase.failed:
        return loc.internet_speed_failed;
    }
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.quality, required this.loc});

  final InternetSpeedQuality quality;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final color = switch (quality) {
      InternetSpeedQuality.excellent => AppColor.success,
      InternetSpeedQuality.good => AppColor.teal,
      InternetSpeedQuality.fair => AppColor.warning,
      InternetSpeedQuality.poor => AppColor.error,
      InternetSpeedQuality.unknown => Theme.of(context).colorScheme.primary,
    };
    final text = switch (quality) {
      InternetSpeedQuality.excellent => loc.internet_speed_quality_excellent,
      InternetSpeedQuality.good => loc.internet_speed_quality_good,
      InternetSpeedQuality.fair => loc.internet_speed_quality_fair,
      InternetSpeedQuality.poor => loc.internet_speed_quality_poor,
      InternetSpeedQuality.unknown => loc.internet_speed_idle_hint,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.snapshot,
    required this.loc,
    required this.scheme,
  });

  final _SpeedSnapshot snapshot;
  final AppLocalizations loc;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.bolt_rounded,
            label: loc.internet_speed_ping,
            value: formatPingMs(snapshot.pingMs),
            unit: loc.internet_speed_ms,
            highlighted: snapshot.phase == InternetSpeedPhase.ping,
            scheme: scheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.south_rounded,
            label: loc.internet_speed_download,
            value: formatSpeedMbps(
              snapshot.phase == InternetSpeedPhase.download
                  ? snapshot.liveMbps
                  : snapshot.downloadMbps,
            ),
            unit: loc.internet_speed_mbps,
            highlighted: snapshot.phase == InternetSpeedPhase.download,
            scheme: scheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.north_rounded,
            label: loc.internet_speed_upload,
            value: formatSpeedMbps(snapshot.uploadDisplay),
            unit: loc.internet_speed_mbps,
            highlighted: snapshot.phase == InternetSpeedPhase.upload,
            scheme: scheme,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.highlighted,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool highlighted;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final border = highlighted
        ? scheme.primary.withValues(alpha: 0.45)
        : scheme.primary.withValues(alpha: 0.08);
    final fill = highlighted
        ? scheme.primary.withValues(alpha: 0.06)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 8),
          _AnimatedNumberText(
            value: double.tryParse(value) ?? 0,
            decimals: value.contains('.') ? 1 : 0,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNumberText extends StatelessWidget {
  const _AnimatedNumberText({
    required this.value,
    required this.style,
    this.decimals = 0,
  });

  final double value;
  final int decimals;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final text = decimals == 0
            ? animated.round().toString()
            : animated.toStringAsFixed(decimals);
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}
