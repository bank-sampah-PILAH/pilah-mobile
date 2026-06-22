import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const route = '/splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in animation shortly after render
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });

    // Navigate to Login Page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: SafeArea(
          child: Stack(
            children: [
              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // PILAH text
                    Text(
                      'PILAH',
                      style: AppTextStyle.headline1.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Sistem Manajemen Bank Sampah',
                      style: AppTextStyle.small.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom content
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bank Sampah BTH, Depok',
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
