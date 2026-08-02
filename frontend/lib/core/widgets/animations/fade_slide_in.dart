import 'package:flutter/material.dart';

import '../../../app/themes/app_spacing.dart';

/// A subtle fade + slide-up entrance (200–250ms, [AppMotion.medium]) for a
/// section/card as it first appears — optionally staggered via [delay] so
/// a screen's sections cascade in rather than popping in all at once.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn(
      {required this.child, this.delay = Duration.zero, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppMotion.medium,
      curve: AppMotion.curve.enter,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: AppMotion.medium,
        curve: AppMotion.curve.enter,
        child: widget.child,
      ),
    );
  }
}
