class Endpoints {
  // auth
  static const String login = "auth/login";
  static const String loginWithGoogle = "/api/v1/auth/google";
  static const String registerGoogleUser = "/api/v1/auth/google/register";
  static const String authMe = "/api/v1/auth/me";
  static const String logout = "/api/v1/auth/logout";

  // onboarding
  static const String onboardingProfile = "/api/v1/onboarding/profile";
  static const String onboardingBankSampah = "/api/v1/onboarding/bank-sampah";
  static const String invitesAccept = "/api/v1/invites/accept";
  static const String onboardingNasabah = "/api/v1/onboarding/nasabah";
  static const String bankSampahDirectory = "/api/v1/bank-sampah";
  static const String nasabahMe = "/api/v1/nasabah/me";

  // profile / bank sampah / team / settings
  static const String bankSampahMe = "/api/v1/bank-sampah/me";
  static const String team = "/api/v1/team";
  static const String teamInvite = "/api/v1/team/invite";
  static const String waTemplate = "/api/v1/pengaturan/wa-template";

  // dashboard
  static const String dashboardStats = "/api/v1/dashboard/stats";
}
