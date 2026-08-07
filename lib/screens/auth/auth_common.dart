import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Cereont brand mark + heading used at the top of the auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.accent]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.hub, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// "Continue with Google" button.
class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  const GoogleButton({super.key, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Text('Continue with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      )),
                ],
              ),
      ),
    );
  }
}

/// A small "or" divider.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Divider(color: Theme.of(context).dividerColor));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: Theme.of(context).textTheme.bodySmall),
        ),
        line,
      ],
    );
  }
}

/// Inline error banner shown above the form on failures.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5484D).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE5484D), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }
}

/// Google's multi-colour "G" drawn with a CustomPainter (no network asset).
class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({required this.size});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final stroke = w * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final arcRect = rect.deflate(stroke / 2);

    // Blue (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, _rad(-20), _rad(80), false, paint);
    // Green (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, _rad(60), _rad(70), false, paint);
    // Yellow (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, _rad(130), _rad(70), false, paint);
    // Red (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, _rad(200), _rad(80), false, paint);

    // The horizontal bar of the "G".
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.52, h * 0.42, w * 0.46, h * 0.16),
      bar,
    );
  }

  double _rad(double deg) => deg * 3.1415926535 / 180.0;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
