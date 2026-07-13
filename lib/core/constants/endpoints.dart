class Endpoints {
  // auth
  static const String login = "auth/login";
  static const String loginWithGoogle = "/api/v1/auth/google";
  static const String authMe = "/api/v1/auth/me";
  static const String logout = "/api/v1/auth/logout";

  // onboarding
  static const String onboardingProfile = "/api/v1/onboarding/profile";
  static const String onboardingBankSampah = "/api/v1/onboarding/bank-sampah";

  // profile / bank sampah / team / settings
  static const String bankSampahMe = "/api/v1/bank-sampah/me";
  static const String team = "/api/v1/team";
  static const String teamInvite = "/api/v1/team/invite";
  static const String waTemplate = "/api/v1/pengaturan/wa-template";

  // dashboard
  static const String dashboardStats = "/api/v1/dashboard/stats";
}
