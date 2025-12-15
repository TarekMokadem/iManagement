import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Fade + slide qui ne se déclenche que lorsque le widget est visible à l'écran.
/// Inspiré des effets \"scroll reveal\" type FlutterFX.
class FxLazyFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double offsetY;
  final double visibilityThreshold;

  const FxLazyFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.offsetY = 24,
    this.visibilityThreshold = 0.25,
  });

  @override
  State<FxLazyFadeIn> createState() => _FxLazyFadeInState();
}

class _FxLazyFadeInState extends State<FxLazyFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<double>(begin: widget.offsetY, end: 0).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_hasAnimated) return;
    if (info.visibleFraction >= widget.visibilityThreshold) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: _onVisibilityChanged,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _offset.value),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}


