import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/app_navigator.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/complaints/dialogs/raise_complaint_dialog.dart';
import '../dialogs/create_event_dialog.dart';
import '../dialogs/create_task_dialog.dart';
import '../dialogs/create_todo_dialog.dart';
import '../dialogs/schedule_meeting_dialog.dart';

/// Navigator observer that detects when a modal/popup route (like a dialog) is open.
class ModalCheckObserver extends NavigatorObserver {
  static final ModalCheckObserver instance = ModalCheckObserver._();
  ModalCheckObserver._();

  static final ValueNotifier<bool> isModalOpen = ValueNotifier<bool>(false);
  static int _modalCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PopupRoute) {
      _modalCount++;
      isModalOpen.value = true;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PopupRoute) {
      _modalCount = (_modalCount - 1).clamp(0, 999);
      isModalOpen.value = _modalCount > 0;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PopupRoute) {
      _modalCount = (_modalCount - 1).clamp(0, 999);
      isModalOpen.value = _modalCount > 0;
    }
  }
}

class DraggableRadialMenuOverlay extends StatefulWidget {
  final Widget child;

  const DraggableRadialMenuOverlay({
    super.key,
    required this.child,
  });

  @override
  State<DraggableRadialMenuOverlay> createState() =>
      _DraggableRadialMenuOverlayState();
}

class _RadialMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RadialMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DraggableRadialMenuOverlayState extends State<DraggableRadialMenuOverlay>
    with TickerProviderStateMixin {
  static const double _buttonSize = 54.0;
  static const double _satelliteSize = 44.0;
  static const double _arcRadius = 94.0;
  static const double _edgeMargin = 16.0;

  Offset? _position;
  bool _isDockedOnRight = true;
  bool _isOpen = false;
  bool _isDragging = false;
  Offset _panStartGlobal = Offset.zero;

  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  late final AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _expandController.reverse();
    }
  }

  void _toggleMenu() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _snapToEdge(Size screenSize, EdgeInsets padding) {
    if (_position == null) return;
    final topBound = padding.top + 60.0;
    final bottomBound = screenSize.height - padding.bottom - _buttonSize - 70.0;
    final clampedY = _position!.dy.clamp(topBound, bottomBound);

    final centerX = _position!.dx + _buttonSize / 2;
    final dockRight = centerX >= screenSize.width / 2;
    final targetX = dockRight
        ? screenSize.width - _buttonSize - _edgeMargin
        : _edgeMargin;

    final targetPos = Offset(targetX, clampedY);
    _isDockedOnRight = dockRight;

    _snapAnimation = Tween<Offset>(
      begin: _position!,
      end: targetPos,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
        setState(() {
          _position = _snapAnimation.value;
        });
      });

    _snapController.forward(from: 0.0);
  }

  List<_RadialMenuItem> _buildMenuItems(BuildContext context) {
    final s = AppStrings.of(context);
    final targetContext = AppNavigator.navigatorKey.currentContext ?? context;

    return [
      _RadialMenuItem(
        label: s.newTask,
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF2563EB), // Vibrant Blue
        onTap: () {
          _closeMenu();
          CreateTaskDialog.show(targetContext);
        },
      ),
      _RadialMenuItem(
        label: s.newTodo,
        icon: Icons.playlist_add_check_rounded,
        color: const Color(0xFFEA580C), // Vibrant Orange
        onTap: () {
          _closeMenu();
          CreateTodoDialog.show(targetContext);
        },
      ),
      _RadialMenuItem(
        label: s.newMeeting,
        icon: Icons.groups_rounded,
        color: const Color(0xFF7C3AED), // Vibrant Purple
        onTap: () {
          _closeMenu();
          ScheduleMeetingDialog.show(targetContext);
        },
      ),
      _RadialMenuItem(
        label: s.newEvent,
        icon: Icons.celebration_rounded,
        color: const Color(0xFFD97706), // Vibrant Amber
        onTap: () {
          _closeMenu();
          CreateEventDialog.show(targetContext);
        },
      ),
      _RadialMenuItem(
        label: s.raiseRequest,
        icon: Icons.campaign_rounded,
        color: const Color(0xFFBE123C), // Vibrant Rose/Crimson
        onTap: () {
          _closeMenu();
          RaiseComplaintDialog.show(targetContext);
        },
      ),
    ];
  }

  /// Compute angle (in radians) for each item index (0..4) based on edge docking.
  double _getItemAngle(int index, int totalCount) {
    // 5 items spanned over 160 degrees
    if (_isDockedOnRight) {
      // Facing LEFT into the screen:
      // Angles: 260 deg (top) -> 220 deg -> 180 deg (middle) -> 140 deg -> 100 deg (bottom)
      const double startAngleDeg = 260.0;
      const double endAngleDeg = 100.0;
      final step = (startAngleDeg - endAngleDeg) / (totalCount - 1);
      final angleDeg = startAngleDeg - (index * step);
      return angleDeg * (math.pi / 180.0);
    } else {
      // Facing RIGHT into the screen:
      // Angles: -80 deg (top) -> -40 deg -> 0 deg (middle) -> +40 deg -> +80 deg (bottom)
      const double startAngleDeg = -80.0;
      const double endAngleDeg = 80.0;
      final step = (endAngleDeg - startAngleDeg) / (totalCount - 1);
      final angleDeg = startAngleDeg + (index * step);
      return angleDeg * (math.pi / 180.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState is AuthenticatedState;

    if (!isAuthenticated) {
      return widget.child;
    }

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Default starting position at bottom-right
    if (_position == null) {
      _position = Offset(
        screenSize.width - _buttonSize - _edgeMargin,
        (screenSize.height * 0.72).clamp(
          padding.top + 60.0,
          screenSize.height - padding.bottom - _buttonSize - 70.0,
        ),
      );
      _isDockedOnRight = true;
    }

    final menuItems = _buildMenuItems(context);
    final buttonCenter = Offset(
      _position!.dx + _buttonSize / 2,
      _position!.dy + _buttonSize / 2,
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Underlying screen content
          widget.child,

          // Observers check: hide button during modal dialogs unless menu is already open
          ValueListenableBuilder<bool>(
            valueListenable: ModalCheckObserver.isModalOpen,
            builder: (context, isModalOpen, _) {
              if (isModalOpen && !_isOpen) {
                return const SizedBox.shrink();
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen backdrop barrier to dismiss radial menu
                  if (_isOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeMenu,
                        child: AnimatedBuilder(
                          animation: _expandAnimation,
                          builder: (context, _) => Container(
                            color: Colors.black.withOpacity(
                              (0.25 * _expandAnimation.value).clamp(0.0, 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Animated radial satellite buttons + labels
                  if (_expandAnimation.value > 0.001 || _isOpen)
                    AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, _) {
                        final progress = _expandAnimation.value;
                        final currentRadius = _arcRadius * progress;

                        final widgets = <Widget>[];
                        for (int i = 0; i < menuItems.length; i++) {
                          widgets.addAll(
                            _buildSatelliteWidgets(
                              item: menuItems[i],
                              angle: _getItemAngle(i, menuItems.length),
                              center: buttonCenter,
                              radius: currentRadius,
                              progress: progress,
                              screenSize: screenSize,
                            ),
                          );
                        }

                        return Stack(
                          fit: StackFit.expand,
                          children: widgets,
                        );
                      },
                    ),

                  // Draggable Main Action Button (Plus / Close)
                  Positioned(
                    left: _position!.dx,
                    top: _position!.dy,
                    child: GestureDetector(
                      onPanStart: (details) {
                        _panStartGlobal = details.globalPosition;
                        _isDragging = false;
                      },
                      onPanUpdate: (details) {
                        final dist = (details.globalPosition - _panStartGlobal).distance;
                        if (dist > 7.0) {
                          _isDragging = true;
                          if (_isOpen) {
                            _closeMenu();
                          }
                          final topBound = padding.top + 60.0;
                          final bottomBound =
                              screenSize.height - padding.bottom - _buttonSize - 70.0;

                          setState(() {
                            _position = Offset(
                              (_position!.dx + details.delta.dx).clamp(
                                8.0,
                                screenSize.width - _buttonSize - 8.0,
                              ),
                              (_position!.dy + details.delta.dy).clamp(
                                topBound,
                                bottomBound,
                              ),
                            );
                          });
                        }
                      },
                      onPanEnd: (details) {
                        if (_isDragging) {
                          _snapToEdge(screenSize, padding);
                        } else {
                          _toggleMenu();
                        }
                      },
                      child: _buildMainFab(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainFab(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        // Interpolate background between app primary color and white
        final bgColor = Color.lerp( Color(0xFF2563EB).withOpacity(.5), Colors.white, progress)!;
        final iconColor = Color.lerp(Colors.white, const Color(0xFF0F172A), progress)!;

        return Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: progress > 0.5
                ? Border.all(color: const Color(0xFFE2E8F0), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: progress * (math.pi / 4), // 45 degree rotation transforms + into x
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: iconColor,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSatelliteWidgets({
    required _RadialMenuItem item,
    required double angle,
    required Offset center,
    required double radius,
    required double progress,
    required Size screenSize,
  }) {
    final itemCenterX = center.dx + radius * math.cos(angle);
    final itemCenterY = center.dy + radius * math.sin(angle);

    final circleLeft = itemCenterX - _satelliteSize / 2;
    final circleTop = itemCenterY - _satelliteSize / 2;

    final scale = progress.clamp(0.0, 1.0);
    final opacity = progress.clamp(0.0, 1.0);

    return [
      // Circular Satellite Button
      Positioned(
        left: circleLeft,
        top: circleTop,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Semantics(
              label: item.label,
              button: true,
              child: GestureDetector(
                onTap: item.onTap,
                child: Container(
                  width: _satelliteSize,
                  height: _satelliteSize,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Label Pill attached to satellite button
      if (_isDockedOnRight)
        Positioned(
          right: screenSize.width - circleLeft + 8.0,
          top: itemCenterY - 14.0,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _buildLabelPill(item),
            ),
          ),
        )
      else
        Positioned(
          left: circleLeft + _satelliteSize + 8.0,
          top: itemCenterY - 14.0,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _buildLabelPill(item),
            ),
          ),
        ),
    ];
  }

  Widget _buildLabelPill(_RadialMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.88),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          item.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
