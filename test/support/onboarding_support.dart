import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';

import 'stub_api.dart';

/// A real [OnboardingCubit] over the real data source, with only HTTP stubbed.
OnboardingCubit buildOnboardingCubit(StubApi api) =>
    OnboardingCubit(OnboardingRemoteDataSourceImpl(api.network));
