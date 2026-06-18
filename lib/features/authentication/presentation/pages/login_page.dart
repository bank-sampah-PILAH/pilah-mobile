import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_background_wrapper.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_footer.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/welcome_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const route = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LoginBackgroundWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 40),
                  LoginHeader(),
                  SizedBox(height: 48),
                  WelcomeCard(),
                  SizedBox(height: 32),
                  LoginButton(),
                  SizedBox(height: 48),
                  LoginFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
