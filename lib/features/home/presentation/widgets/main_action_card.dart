import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MainActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? badge;
  final bool isHighlighted;
  final String? lottieAsset;

  const MainActionCard({
    super.key, 
    required this.icon, 
    required this.title, 
    required this.subtitle, 
    required this.gradientColors, 
    required this.onTap, 
    this.badge,
    this.isHighlighted = false,
    this.lottieAsset,
  });

  @override
  State<MainActionCard> createState() => _MainActionCardState();
}

class _MainActionCardState extends State<MainActionCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    if (widget.isHighlighted) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.gradientColors.first;
    final secondaryColor = widget.gradientColors.last;
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowValue = widget.isHighlighted ? _glowController.value : 0.0;
        
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.97).animate(
            CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
          ),
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _scaleController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _scaleController.reverse();
              widget.onTap();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _scaleController.reverse();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                      ? [primaryColor.withOpacity(0.15), secondaryColor.withOpacity(0.08)]
                      : [primaryColor.withOpacity(0.08), secondaryColor.withOpacity(0.03)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPressed ? primaryColor.withOpacity(0.6) : primaryColor.withOpacity(isDark ? 0.3 : 0.2),
                  width: _isPressed ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.25 : 0.15),
                    blurRadius: _isPressed ? 24 : 16,
                    offset: Offset(0, _isPressed ? 6 : 8),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                  if (widget.isHighlighted)
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1 + (glowValue * 0.15)),
                      blurRadius: 30 + (glowValue * 10),
                      spreadRadius: 2 + (glowValue * 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.lottieAsset != null
                          ? Lottie.asset(
                              widget.lottieAsset!,
                              fit: BoxFit.cover,
                              repeat: true,
                            )
                          : Icon(widget.icon, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.title, 
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1f2937),
                                fontSize: 17, 
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (widget.badge != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: widget.gradientColors),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.badge!, 
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 10, 
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle, 
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6b7280), 
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Arrow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isPressed ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}