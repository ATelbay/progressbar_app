import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

/// The platform owns push/back gestures. Our timing and reduced-motion path
/// apply to every MaterialPage produced by go_router.
class PbPageTransitionsBuilder extends PageTransitionsBuilder {
  const PbPageTransitionsBuilder(
    this.platformBuilder, {
    this.reducedMotion = false,
  });

  final PageTransitionsBuilder platformBuilder;
  final bool reducedMotion;

  @override
  Duration get transitionDuration =>
      reducedMotion ? PbMotion.reducedTransition : PbMotion.pageEnter;

  @override
  Duration get reverseTransitionDuration =>
      reducedMotion ? PbMotion.reducedTransition : PbMotion.pageExit;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => reducedMotion
      ? (context, animation, secondaryAnimation, allowSnapshotting, child) =>
            child
      : platformBuilder.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      // Keep the platform gesture detector even when spatial motion is removed.
      final content = platformBuilder.buildTransitions(
        route,
        context,
        const AlwaysStoppedAnimation(1),
        const AlwaysStoppedAnimation(0),
        child,
      );
      return FadeTransition(opacity: animation, child: content);
    }
    return platformBuilder.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Persistent branch Navigators move beneath the fixed glass tab bar. Starting
/// another transition samples the current composition, including a rapid return
/// to a fading branch, so neither state nor animation jumps back to its start.
class PbBranchTransition extends StatefulWidget {
  const PbBranchTransition({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<PbBranchTransition> createState() => _PbBranchTransitionState();
}

class _PbBranchTransitionState extends State<PbBranchTransition>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: PbMotion.tabSwitch,
    value: 1,
  );
  late int _target = widget.index;
  late List<double> _starts = [
    for (var i = 0; i < widget.children.length; i++) i == _target ? 1 : 0,
  ];
  late List<Offset> _begins = List.filled(widget.children.length, Offset.zero);
  late List<Offset> _ends = List.filled(widget.children.length, Offset.zero);
  bool _reduced = false;

  double get _progress => Curves.easeOutCubic.transform(_controller.value);
  double _opacity(int i) =>
      lerpDouble(_starts[i], i == _target ? 1 : 0, _progress)!.clamp(0, 1);
  Offset _position(int i) =>
      _reduced ? Offset.zero : Offset.lerp(_begins[i], _ends[i], _progress)!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced == reduced) return;
    _reduced = reduced;
    _controller.duration = reduced
        ? PbMotion.reducedTransition
        : PbMotion.tabSwitch;
    if (_controller.isAnimating && reduced) {
      _controller.animateTo(1, duration: PbMotion.reducedTransition);
    }
  }

  @override
  void didUpdateWidget(PbBranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _target = widget.index;
      _starts = [
        for (var i = 0; i < widget.children.length; i++) i == _target ? 1 : 0,
      ];
      _begins = _ends = List.filled(widget.children.length, Offset.zero);
      _controller.value = 1;
      return;
    }
    if (widget.index == oldWidget.index) return;
    final starts = List.generate(widget.children.length, _opacity);
    final positions = List.generate(widget.children.length, _position);
    final direction = widget.index > oldWidget.index ? 1.0 : -1.0;
    _starts = starts;
    _begins = positions;
    _target = widget.index;
    if (_starts[_target] == 0) {
      _begins[_target] = Offset(direction * PbSpace.s4, 0);
    }
    _ends = [
      for (var i = 0; i < widget.children.length; i++)
        i == _target ? Offset.zero : Offset(-direction * PbSpace.s4, 0),
    ];
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        for (final i in [
          for (var i = 0; i < widget.children.length; i++)
            if (i != widget.index) i,
          widget.index,
        ])
          KeyedSubtree(
            key: ValueKey(i),
            child: AnimatedBuilder(
              animation: _controller,
              child: RepaintBoundary(child: widget.children[i]),
              builder: (context, child) {
                final active = i == widget.index;
                final opacity = _opacity(i);
                return Offstage(
                  offstage: !active && opacity == 0,
                  child: TickerMode(
                    enabled: active,
                    child: IgnorePointer(
                      ignoring: !active,
                      child: ExcludeSemantics(
                        excluding: !active,
                        child: ExcludeFocus(
                          excluding: !active,
                          child: Transform.translate(
                            offset: _position(i),
                            child: Opacity(opacity: opacity, child: child),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}
