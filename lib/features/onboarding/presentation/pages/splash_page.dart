import 'dart:developer';

import 'package:boilerplate/features/onboarding/presentation/blocs/events/get_user_event.dart';
import 'package:boilerplate/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:boilerplate/features/onboarding/presentation/blocs/onboarding_states.dart';
import 'package:boilerplate/features/onboarding/presentation/blocs/states/onboarding_states.dart';
import 'package:boilerplate/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:boilerplate/features/product/presentation/home/pages/product_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../design/constants/colors.dart';
import '../../../../design/constants/text_style.dart';
import '../../../../services/di.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const route = '/splash';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => di<OnboardingBloc>(), child: const SplashPageView());
  }
}

class SplashPageView extends StatefulWidget {
  const SplashPageView({super.key});

  @override
  State<SplashPageView> createState() => _SplashPageViewState();
}

class _SplashPageViewState extends State<SplashPageView> {
  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(GetUserEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<OnboardingBloc, OnboardingStates>(
        listener: (context, state) {
          log(state.toString());
          if (state is OnboardingLoggedState) {
            context.goNamed(ProductHomePage.route);
          }
          if (state is OnboardingNewState) {
            context.goNamed(OnboardingPage.route);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 100,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Flutter Shop',
              style:
                  AppTextStyle.headline1.copyWith(color: AppColors.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
