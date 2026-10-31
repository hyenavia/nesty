import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Animated splash: wordmark, tagline, mascot on soft hills, progress bar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.duration = const Duration(milliseconds: 1700)});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HillsPainter())),
          Positioned(
              left: 28,
              top: 90,
              child: Icon(Icons.cloud_rounded,
                  size: 58, color: AppColors.peach.withValues(alpha: 0.7))),
          Positioned(
              right: 22,
              top: 230,
              child: Icon(Icons.cloud_rounded,
                  size: 44, color: AppColors.peach.withValues(alpha: 0.55))),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      'nesty',
                      style: GoogleFonts.nunito(
                        fontSize: 72,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brown,
                      ),
                    ),
                    const Positioned(
                      right: -4,
                      top: -16,
                      child: Icon(Icons.favorite_rounded,
                          size: 22, color: AppColors.safe),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Little Things, Taken Care Of.',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.brown,
                  ),
                ),
                const Spacer(flex: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutBack,
                  builder: (context, v, child) => Opacity(
                    opacity: ((v - 0.85) / 0.15).clamp(0.0, 1.0).toDouble(),
                    child: Transform.scale(scale: v, child: child),
                  ),
                  child: Image.asset('assets/images/mascot.png', width: 250),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: duration,
                    curve: Curves.easeInOut,
                    builder: (context, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        color: AppColors.peachDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  const _HillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.3, size.height * 0.93),
          width: size.width * 1.5,
          height: size.height * 0.36),
      Paint()..color = AppColors.peach.withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width * 0.88, size.height * 0.88),
          width: size.width * 0.95,
          height: size.height * 0.3),
      Paint()..color = AppColors.mint.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
