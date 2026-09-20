import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class RoleHandoffPage extends StatelessWidget {
  final String title;
  final String message;
  final bool registrationInProgress;

  const RoleHandoffPage({
    super.key,
    required this.title,
    required this.message,
    required this.registrationInProgress,
  });

  static const registerNasabahRoute = '/register-nasabah';
  static const nasabahDashboardRoute = '/nasabah-dashboard';
  static const registerIndukRoute = '/register-bank-sampah-induk';
  static const indukDashboardRoute = '/pengelola-induk-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text('PILAH'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      registrationInProgress
                          ? Icons.assignment_outlined
                          : Icons.check_circle_outline,
                      color: AppColors.greenDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.headline1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.grey100,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
