import 'dart:ui';

import 'package:flutter/material.dart';

/// Animation inspirée de "Text Reveal Fade Top" (FlutterFX)
/// Texte qui apparaît avec un léger flou + translation verticale depuis le haut.
class FxTextFadeTop extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double translateDy;

  const FxTextFadeTop({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.curve = Curves.easeOutCubic,
    this.translateDy = 12.0,
  });

  @override
  State<FxTextFadeTop> createState() => _FxTextFadeTopState();
}

class _FxTextFadeTopState extends State<FxTextFadeTop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  late final Animation<double> _blur;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<double>(begin: -widget.translateDy, end: 0).animate(curved);
    _blur = Tween<double>(begin: 6, end: 0).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _offset.value),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: _blur.value,
                sigmaY: _blur.value,
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}


