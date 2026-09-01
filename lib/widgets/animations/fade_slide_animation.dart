import 'package:flutter/material.dart';

class FadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final double yOffset;
  final Duration duration;
  final Duration delay;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.yOffset = 40.0,
    this.duration = const Duration(milliseconds: 500),
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<FadeSlideAnimation> createState() => _FadeSlideAnimationState();
}

class _FadeSlideAnimationState extends State<FadeSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.yOffset * (1 - _animation.value)),
          child: Opacity(opacity: _animation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
