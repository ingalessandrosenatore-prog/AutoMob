abstract final class AppRoutePaths {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const registration = '/auth/registration';
  static const emailVerification = '/auth/verify-email';
  static const workshop = '/workshop';
  static const settingsSegment = 'settings';
  static const subscription = '/subscription';
  static const serviceRequests = '/service-requests';
  static const subscriptionPlanSegment = 'plan';
  static const workshopProfileSegment = 'profile';

  static const vehicleConfigurationSegment = 'vehicles/:vehicleId';
  static const workRegistrationSegment = 'works/new';
  static const workDetailSegment = 'works/:workId';

  static String get settings => '$workshop/settings';
  static String get subscriptionPlan => '$subscription/plan';
  static String get workshopProfile => '$subscription/profile';

  static String vehicleConfiguration(String vehicleId) =>
      '$workshop/vehicles/$vehicleId';

  static String workRegistration(String vehicleId) =>
      '${vehicleConfiguration(vehicleId)}/works/new';

  static String workDetail(String vehicleId, String workId) =>
      '${vehicleConfiguration(vehicleId)}/works/$workId';
}
