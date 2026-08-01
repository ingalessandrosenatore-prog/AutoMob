abstract final class AppRoutePaths {
  static const splash = '/splash';
  static const login = '/auth/login';
  static const registration = '/auth/registration';
  static const emailVerification = '/auth/verify-email';
  static const workshop = '/workshop';
  static const subscription = '/subscription';

  static const vehicleConfigurationSegment = 'vehicles/:vehicleId';
  static const workRegistrationSegment = 'works/new';
  static const workDetailSegment = 'works/:workId';

  static String vehicleConfiguration(String vehicleId) =>
      '$workshop/vehicles/$vehicleId';

  static String workRegistration(String vehicleId) =>
      '${vehicleConfiguration(vehicleId)}/works/new';

  static String workDetail(String vehicleId, String workId) =>
      '${vehicleConfiguration(vehicleId)}/works/$workId';
}
