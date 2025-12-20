import 'dart:math';

import 'package:flutter/material.dart';

class FloatingAIButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isChatActive;

  const FloatingAIButton({
    super.key,
    required this.onTap,
    this.isChatActive = false,
  });

  @override
  State<FloatingAIButton> createState() => _FloatingAIButtonState();
}

class _FloatingAIButtonState extends State<FloatingAIButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing ring effect
              if (!widget.isChatActive)
                Opacity(
                  opacity: 1.0 - _pulseAnimation.value,
                  child: Container(
                    width: 80 + (_pulseAnimation.value * 20),
                    height: 80 + (_pulseAnimation.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.3),
                          Colors.deepPurple.withOpacity(0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.1, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

              // Main button
              Transform.scale(
                scale: widget.isChatActive ? 1.0 : _scaleAnimation.value,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isChatActive
                          ? [Colors.deepPurple.shade600, Colors.purple.shade600]
                          : [
                              Colors.deepPurple.shade800,
                              Colors.purple.shade700,
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Animated sparkles
                      if (!widget.isChatActive)
                        ...List.generate(3, (index) {
                          final angle =
                              (index * 120 + _controller.value * 360) *
                              3.14 /
                              180;
                          final radius = 30.0;
                          final x = radius * cos(angle);
                          final y = radius * sin(angle);

                          return Positioned(
                            left: 32.5 + x,
                            top: 32.5 + y,
                            child: Transform.scale(
                              scale: 0.5 + (_controller.value * 0.5),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          );
                        }),

                      // AI Icon
                      Center(
                        child: Icon(
                          widget.isChatActive
                              ? Icons.smart_toy
                              : Icons.auto_awesome,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notification dot
              if (widget.isChatActive)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
