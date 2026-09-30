import 'package:auto_mob_v1/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la home usa il nome dell utente autenticato quando disponibile', () {
    const user = AppAuthUser(
      id: 'user-1',
      email: 'mario@automob.it',
      displayName: 'Mario Rossi',
    );

    expect(user.homeLabel, 'Mario Rossi');
  });

  test('la home usa l email quando il nome non e disponibile', () {
    const user = AppAuthUser(id: 'user-1', email: 'mario@automob.it');

    expect(user.homeLabel, 'mario@automob.it');
  });
}
