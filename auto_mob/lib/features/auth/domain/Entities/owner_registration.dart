import 'package:equatable/equatable.dart';

class OwnerRegistration extends Equatable {
  const OwnerRegistration({
    this.fullName = '',
    this.phone = '',
    this.postalCode = '',
  });

  final String fullName;
  final String phone;
  final String postalCode;

  String? validate({bool requireName = true}) {
    if (requireName && fullName.trim().isEmpty) return 'Inserisci il tuo nome.';
    if (fullName.trim().length > 150) return 'Il nome è troppo lungo.';
    if (!RegExp(r'^\+?[0-9 ()-]{8,30}$').hasMatch(phone.trim()) ||
        phone.replaceAll(RegExp('[^0-9]'), '').length < 8 ||
        phone.replaceAll(RegExp('[^0-9]'), '').length > 15) {
      return 'Inserisci un numero di telefono valido.';
    }
    if (!RegExp(r'^[0-9]{5}$').hasMatch(postalCode.trim())) {
      return 'Inserisci un CAP italiano valido.';
    }
    return null;
  }

  @override
  List<Object> get props => [fullName, phone, postalCode];
}

class OwnerAccess extends Equatable {
  const OwnerAccess({required this.needsCompletion, required this.profile});
  final bool needsCompletion;
  final OwnerRegistration profile;

  @override
  List<Object> get props => [needsCompletion, profile];
}
