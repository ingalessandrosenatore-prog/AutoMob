import 'package:automob_backoffice_mech/core/error/failure.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/entities/subscription_overview.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:automob_backoffice_mech/features/subscription/domain/usecases/get_subscription_overview.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:automob_backoffice_mech/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  final overview = SubscriptionOverview(
    workshopName: 'Officina Test',
    mechanicCode: '123456',
    plan: SubscriptionPlan.premium,
    status: SubscriptionStatus.active,
    expiresAt: DateTime(2027),
    daysRemaining: 30,
    linkedVehicles: 7,
  );

  blocTest<SubscriptionBloc, SubscriptionState>(
    'carica il riepilogo alla prima apertura',
    build: () => SubscriptionBloc(
      getSubscriptionOverview: GetSubscriptionOverview(
        _SubscriptionRepository(Right(overview)),
      ),
    ),
    act: (bloc) => bloc.add(const SubscriptionStarted()),
    expect: () => [const SubscriptionLoading(), SubscriptionReady(overview)],
  );

  blocTest<SubscriptionBloc, SubscriptionState>(
    'espone un errore recuperabile',
    build: () => SubscriptionBloc(
      getSubscriptionOverview: GetSubscriptionOverview(
        _SubscriptionRepository(const Left(ServerFailure())),
      ),
    ),
    act: (bloc) => bloc.add(const SubscriptionStarted()),
    expect: () => [
      const SubscriptionLoading(),
      const SubscriptionLoadFailure(
        'Si è verificato un errore. Riprova tra qualche istante.',
      ),
    ],
  );

  test('refresh ricarica il riepilogo anche dallo stato pronto', () async {
    final repository = _CountingSubscriptionRepository(overview);
    final bloc = SubscriptionBloc(
      getSubscriptionOverview: GetSubscriptionOverview(repository),
    );
    addTearDown(bloc.close);

    bloc.add(const SubscriptionStarted());
    await expectLater(
      bloc.stream,
      emitsInOrder([const SubscriptionLoading(), SubscriptionReady(overview)]),
    );

    bloc.add(const SubscriptionRetryRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder([const SubscriptionLoading(), SubscriptionReady(overview)]),
    );

    expect(repository.calls, 2);
  });
}

final class _SubscriptionRepository implements SubscriptionRepository {
  const _SubscriptionRepository(this.result);

  final Either<Failure, SubscriptionOverview> result;

  @override
  Future<Either<Failure, SubscriptionOverview>> getOverview() async => result;
}

final class _CountingSubscriptionRepository implements SubscriptionRepository {
  _CountingSubscriptionRepository(this.overview);

  final SubscriptionOverview overview;
  int calls = 0;

  @override
  Future<Either<Failure, SubscriptionOverview>> getOverview() async {
    calls++;
    return Right(overview);
  }
}
