import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';

import 'stub_api.dart';

OnboardingRemoteDataSource buildOnboardingDataSource(StubApi api) =>
    OnboardingRemoteDataSourceImpl(api.network);

ProviderContainer buildOnboardingContainer(
  OnboardingRemoteDataSource dataSource,
) =>
    ProviderContainer(overrides: [
      onboardingProvider.overrideWith(() => OnboardingNotifier(dataSource)),
    ]);

Widget withOnboarding(Widget child, OnboardingRemoteDataSource dataSource) =>
    ProviderScope(
      overrides: [
        onboardingProvider.overrideWith(
          () => OnboardingNotifier(dataSource),
        ),
      ],
      child: child,
    );
