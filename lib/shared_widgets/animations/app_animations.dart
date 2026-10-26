import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Smooth, reusable dialog presentation with cubic scale and fade transitions.
Future<T?> showSmoothDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration duration = const Duration(milliseconds: 280),
  String? barrierLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ?? 'Dialog',
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.5),
    transitionDuration: duration,
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curve = Curves.easeOutCubic.transform(anim1.value);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 3 * anim1.value,
          sigmaY: 3 * anim1.value,
        ),
        child: Transform.scale(
          scale: 0.90 + (0.10 * curve),
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Staggered Slide & Fade in animation for dialog sections and list items.
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offset = const Offset(0, 0.12),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Tactile button micro-animation: scales gently down when pressed.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Slow, elegant pulsing animation for emergency/urgent/overdue badges or active indicators.
/// Continuously zooms in and zooms out with a silky smooth sinusoidal breathing cycle.
class PulsingBadge extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final double maxScale;
  final double minScale;
  final Curve curve;

  const PulsingBadge({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 2400),
    this.maxScale = 1.07,
    this.minScale = 0.96,
    this.curve = Curves.easeInOutSine,
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _opacityAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Animated sleek progress bar with gradient and smooth interpolation.
class AnimatedTaskProgressBar extends StatelessWidget {
  final int progress; // 0 to 100
  final double height;
  final Color? barColor;
  final List<Color>? gradientColors;
  final bool showPercentage;

  const AnimatedTaskProgressBar({
    super.key,
    required this.progress,
    this.height = 7,
    this.barColor,
    this.gradientColors,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, 100) / 100.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colors = gradientColors ??
        (progress >= 100
            ? const [Color(0xFF10B981), Color(0xFF059669)]
            : progress >= 50
                ? const [Color(0xFF3B82F6), Color(0xFF06B6D4)]
                : const [Color(0xFFF59E0B), Color(0xFFEF4444)]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.first,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: clamped),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: constraints.maxWidth * value,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(height / 2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Shimmer skeleton loader for high quality loading states.
class AnimatedShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final dynamic borderRadius;

  const AnimatedShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<AnimatedShimmerBox> createState() => _AnimatedShimmerBoxState();
}

class _AnimatedShimmerBoxState extends State<AnimatedShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    BorderRadiusGeometry radius = BorderRadius.circular(8);
    if (widget.borderRadius is BorderRadiusGeometry) {
      radius = widget.borderRadius as BorderRadiusGeometry;
    } else if (widget.borderRadius is num) {
      radius = BorderRadius.circular((widget.borderRadius as num).toDouble());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (3.0 * _controller.value), 0),
              end: Alignment(-0.5 + (3.0 * _controller.value), 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated rolling number text for stats and counters.
class AnimatedCountText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;
  final int decimalDigits;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 750),
    this.prefix = '',
    this.suffix = '',
    this.decimalDigits = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        final formatted = decimalDigits > 0
            ? animVal.toStringAsFixed(decimalDigits)
            : animVal.round().toString();
        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}

/// Attractive, animated circular progress indicator for loaders, charts, and progress metrics.
/// Replaces the default plain Flutter CircularProgressIndicator with rich gradient arcs,
/// rounded caps, smooth continuous rotation or animated sweep fill, and optional center text/icon.
class AnimatedCircleProgressIndicator extends StatefulWidget {
  final double? value; // 0.0 to 1.0 (if null, behaves as indeterminate spinner)
  final int? progress; // 0 to 100 (convenience for percentages)
  final double size;
  final double? strokeWidth;
  final Color? color;
  final List<Color>? gradientColors;
  final Color? trackColor;
  final Color? backgroundColor;
  final Animation<Color?>? valueColor;
  final bool showPercentage;
  final TextStyle? percentageStyle;
  final Widget? centerChild;
  final bool showGlow;

  const AnimatedCircleProgressIndicator({
    super.key,
    this.value,
    this.progress,
    this.size = 36.0,
    this.strokeWidth,
    this.color,
    this.gradientColors,
    this.trackColor,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = false,
    this.percentageStyle,
    this.centerChild,
    this.showGlow = true,
  });

  @override
  State<AnimatedCircleProgressIndicator> createState() =>
      _AnimatedCircleProgressIndicatorState();
}

class _AnimatedCircleProgressIndicatorState
    extends State<AnimatedCircleProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    if (_isIndeterminate) {
      _rotationController.repeat();
    }
  }

  bool get _isIndeterminate => widget.value == null && widget.progress == null;

  @override
  void didUpdateWidget(AnimatedCircleProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isIndeterminate && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!_isIndeterminate && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTheme = Theme.of(context).colorScheme.primary;

    final resolvedColor = widget.valueColor?.value ?? widget.color;
    final colors = widget.gradientColors ??
        (resolvedColor != null
            ? [resolvedColor, resolvedColor]
            : [
                primaryTheme,
                const Color(0xFF06B6D4), // Cyan accent glow
              ]);

    return LayoutBuilder(
      builder: (context, constraints) {
        double effectiveSize = widget.size;
        if (constraints.hasBoundedWidth && constraints.maxWidth < effectiveSize) {
          effectiveSize = constraints.maxWidth;
        }
        if (constraints.hasBoundedHeight && constraints.maxHeight < effectiveSize) {
          effectiveSize = math.min(effectiveSize, constraints.maxHeight);
        }

        final effectiveStrokeWidth = widget.strokeWidth ??
            (effectiveSize < 20
                ? 2.0
                : (effectiveSize < 28
                    ? 2.4
                    : (effectiveSize < 38
                        ? 3.2
                        : (effectiveSize < 48 ? 3.6 : 4.4))));

        if (_isIndeterminate) {
          return SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(effectiveSize, effectiveSize),
                  painter: _IndeterminateCirclePainter(
                    animationValue: _rotationController.value,
                    strokeWidth: effectiveStrokeWidth,
                    gradientColors: colors,
                    showGlow: widget.showGlow && effectiveSize >= 24,
                    trackColor: widget.backgroundColor ?? widget.trackColor,
                  ),
                );
              },
            ),
          );
        }

        // Determinate mode (with percentage or value)
        final targetRatio = widget.progress != null
            ? (widget.progress!.clamp(0, 100) / 100.0)
            : (widget.value ?? 0.0).clamp(0.0, 1.0);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: targetRatio),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedVal, _) {
            return CustomPaint(
              size: Size(effectiveSize, effectiveSize),
              painter: _DeterminateCirclePainter(
                progress: animatedVal,
                strokeWidth: effectiveStrokeWidth,
                gradientColors: colors,
                trackColor: widget.backgroundColor ??
                    widget.trackColor ??
                    (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                showGlow: widget.showGlow && effectiveSize >= 24,
              ),
              child: SizedBox(
                width: effectiveSize,
                height: effectiveSize,
                child: Center(
                  child: widget.centerChild ??
                      (widget.showPercentage
                          ? Text(
                              '${(animatedVal * 100).toInt()}%',
                              style: widget.percentageStyle ??
                                  TextStyle(
                                    fontSize: effectiveSize * 0.26,
                                    fontWeight: FontWeight.bold,
                                    color: colors.first,
                                  ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _IndeterminateCirclePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final double strokeWidth;
  final List<Color> gradientColors;
  final bool showGlow;
  final Color? trackColor;

  _IndeterminateCirclePainter({
    required this.animationValue,
    required this.strokeWidth,
    required this.gradientColors,
    required this.showGlow,
    this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    // Track ring background
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.75
      ..color = trackColor ?? gradientColors.first.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final rotation = animationValue * 2 * math.pi;

    // Fluid oscillating sweep between 0.4*pi (72 deg) and 1.45*pi (261 deg)
    final sweepProgress = (math.sin(animationValue * 2 * math.pi) + 1.0) / 2.0;
    final sweepAngle = math.max(0.40 * math.pi, sweepProgress * 1.45 * math.pi);

    // Subtle glow if enabled
    if (showGlow && size.width >= 24) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 1.5
        ..color = gradientColors.first.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawArc(rect, rotation, sweepAngle, false, glowPaint);
    }

    // Sweep gradient shader
    final shader = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: [
        gradientColors.last.withValues(alpha: 0.10),
        gradientColors.first,
      ],
      transform: GradientRotation(rotation),
    ).createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = shader;

    canvas.drawArc(rect, rotation, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(_IndeterminateCirclePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _DeterminateCirclePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final List<Color> gradientColors;
  final Color trackColor;
  final bool showGlow;

  _DeterminateCirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
    required this.trackColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (radius <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    // Glow under arc
    if (showGlow && size.width >= 24) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 1.5
        ..color = gradientColors.first.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    }

    final shader = SweepGradient(
      startAngle: 0.0,
      endAngle: sweepAngle,
      colors: gradientColors.length > 1
          ? gradientColors
          : [gradientColors.first, gradientColors.first],
      transform: const GradientRotation(startAngle),
    ).createShader(rect);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = shader;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(_DeterminateCirclePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Convenience alias for AnimatedCircleProgressIndicator
typedef AnimatedCircularProgressIndicator = AnimatedCircleProgressIndicator;
