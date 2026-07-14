import 'package:flutter/material.dart';

class HorizontalScrollWithArrows extends StatefulWidget {
  final Widget child;
  final double arrowButtonSize;
  final double scrollStep;

  const HorizontalScrollWithArrows({
    super.key,
    required this.child,
    this.arrowButtonSize = 32,
    this.scrollStep = 220,
  });

  @override
  State<HorizontalScrollWithArrows> createState() =>
      _HorizontalScrollWithArrowsState();
}

class _HorizontalScrollWithArrowsState extends State<HorizontalScrollWithArrows> {
  final ScrollController _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant HorizontalScrollWithArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canLeft = position.pixels > position.minScrollExtent + 0.5;
    final canRight = position.pixels < position.maxScrollExtent - 0.5;
    if (canLeft == _canScrollLeft && canRight == _canScrollRight) return;
    setState(() {
      _canScrollLeft = canLeft;
      _canScrollRight = canRight;
    });
  }

  Future<void> _scrollBy(double offset) async {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + offset).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    await _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScrollArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: _canScrollLeft,
          size: widget.arrowButtonSize,
          onPressed: () => _scrollBy(-widget.scrollStep),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollMetricsNotification) {
                _updateArrows();
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: widget.child,
            ),
          ),
        ),
        _ScrollArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: _canScrollRight,
          size: widget.arrowButtonSize,
          onPressed: () => _scrollBy(widget.scrollStep),
        ),
      ],
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final double size;
  final VoidCallback onPressed;

  const _ScrollArrowButton({
    required this.icon,
    required this.enabled,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withOpacity(0.28);

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        splashRadius: size * 0.45,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: size * 0.72, color: color),
      ),
    );
  }
}
