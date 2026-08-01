import 'package:equatable/equatable.dart';

final class MechanicRegistration extends Equatable {
  const MechanicRegistration({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.businessName,
    required this.vatNumber,
    required this.streetAddress,
    required this.postalCode,
    required this.municipalityIstatCode,
    required this.municipalityLabel,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String businessName;
  final String vatNumber;
  final String streetAddress;
  final String postalCode;
  final String municipalityIstatCode;
  final String municipalityLabel;

  String get legacyAddress =>
      '${streetAddress.trim()}, ${postalCode.trim()} ${municipalityLabel.trim()}';

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    password,
    businessName,
    vatNumber,
    streetAddress,
    postalCode,
    municipalityIstatCode,
    municipalityLabel,
  ];
}
