import 'package:equatable/equatable.dart';

class MechanicSummary extends Equatable {
  final String id;
  final String code;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? photoUrl;

  const MechanicSummary({
    required this.id,
    required this.code,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
    id,
    code,
    businessName,
    address,
    phone,
    email,
    photoUrl,
  ];
}
