import 'package:automob_backoffice_mech/core/error/app_exception.dart';
import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:automob_backoffice_mech/features/workshop/data/datasources/workshop_remote_data_source.dart';
import 'package:automob_backoffice_mech/features/workshop/data/models/workshop_catalog_model.dart';
import 'package:automob_backoffice_mech/features/workshop/data/repositories/workshop_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockRemoteDataSource extends Mock
    implements WorkshopRemoteDataSource {}

void main() {
  late _MockRemoteDataSource dataSource;
  late WorkshopRepositoryImpl repository;

  setUp(() {
    dataSource = _MockRemoteDataSource();
    repository = WorkshopRepositoryImpl(dataSource);
  });

  test('converte il model e restituisce Right', () async {
    const model = WorkshopCatalogModel(
      mechanic: WorkshopMechanicModel(displayName: 'Marco'),
      vehicles: [],
    );
    when(() => dataSource.getCatalog()).thenAnswer((_) async => model);

    final result = await repository.getCatalog();

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()?.mechanic.displayName, 'Marco');
  });

  test('mappa la violazione RLS in PermissionFailure', () async {
    when(() => dataSource.getCatalog()).thenThrow(
      const WorkshopDataException('permission denied', code: '42501'),
    );

    final result = await repository.getCatalog();

    expect(result.getLeft().toNullable(), isA<PermissionFailure>());
  });

  test('mappa gli altri errori dati in ServerFailure', () async {
    when(
      () => dataSource.getCatalog(),
    ).thenThrow(const WorkshopDataException('errore rpc', code: 'PGRST202'));

    final result = await repository.getCatalog();

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
