import 'package:equatable/equatable.dart';

class MechanicSummary extends Equatable {
  final String id;
  final String code;
  final String businessName;
  final String? address;

  const MechanicSummary({
    required this.id,
    required this.code,
    required this.businessName,
    this.address,
  });

  @override
  List<Object?> get props => [id, code, businessName, address];
}
