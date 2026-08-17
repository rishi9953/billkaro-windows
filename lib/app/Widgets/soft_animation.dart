import 'package:flutter/material.dart';

/// Shared timing for soft, classic screen motion (not bouncy or flashy).
abstract class SoftMotion {
  static const Duration enter = Duration(milliseconds: 460);
  static const Duration enterCompact = Duration(milliseconds: 380);
  static const Duration popIn = Duration(milliseconds: 400);
  static const Duration staggerStep = Duration(milliseconds: 50);
  static const Duration tabFade = Duration(milliseconds: 280);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve tabCurve = Curves.easeInOut;

  static Duration delayForIndex(int index) => staggerStep * index;
}

/// Fades and slides a block in when it first appears on screen.
class SoftAnimatedSection extends StatelessWidget {
  const SoftAnimatedSection({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
    this.duration = SoftMotion.enter,
    this.slideOffset = 14,
  });

  final Widget child;
  final int index;
  final bool enabled;
  final Duration duration;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return _SoftEnterAnimator(
      index: index,
      duration: duration,
      slideOffset: slideOffset,
      child: child,
    );
  }
}

class _SoftEnterAnimator extends StatefulWidget {
  const _SoftEnterAnimator({
    required this.child,
    required this.index,
    required this.duration,
    required this.slideOffset,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final double slideOffset;

  @override
  State<_SoftEnterAnimator> createState() => _SoftEnterAnimatorState();
}

class _SoftEnterAnimatorState extends State<_SoftEnterAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: SoftMotion.curve);
    Future<void>.delayed(SoftMotion.delayForIndex(widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.slideOffset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

class _SoftPopInAnimator extends StatefulWidget {
  const _SoftPopInAnimator({required this.child, required this.index});

  final Widget child;
  final int index;

  @override
  State<_SoftPopInAnimator> createState() => _SoftPopInAnimatorState();
}

class _SoftPopInAnimatorState extends State<_SoftPopInAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: SoftMotion.popIn);
    _animation = CurvedAnimation(parent: _controller, curve: SoftMotion.curve);
    Future<void>.delayed(SoftMotion.delayForIndex(widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.92 + (0.08 * t),
            child: child,
          ),
        );
      },
    );
  }
}

extension SoftMotionEffects on Widget {
  Widget softEnter({int index = 0}) => SoftAnimatedSection(index: index, child: this);

  Widget softEnterCompact({required int index}) => SoftAnimatedSection(
        index: index,
        duration: SoftMotion.enterCompact,
        slideOffset: 12,
        child: this,
      );

  Widget softPopIn({int index = 0}) =>
      _SoftPopInAnimator(index: index, child: this);
}

/// Cross-fades tab bodies while keeping every tab mounted (state preserved).
class SoftTabFadeStack extends StatelessWidget {
  const SoftTabFadeStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (i) {
        final visible = index == i;
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: SoftMotion.tabFade,
            curve: SoftMotion.tabCurve,
            child: children[i],
          ),
        );
      }),
    );
  }
}
