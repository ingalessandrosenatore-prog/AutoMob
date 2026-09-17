import 'package:automob_backoffice_mech/core/router/mechanic_shell_metrics.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/entities/service_request.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/repositories/service_request_repository.dart';
import 'package:automob_backoffice_mech/features/service_requests/domain/usecases/get_service_requests.dart';
import 'package:automob_backoffice_mech/features/service_requests/presentation/bloc/service_requests_cubit.dart';
import 'package:automob_backoffice_mech/features/service_requests/presentation/pages/service_requests_page.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'lista lazy oltre 20 elementi e refresh senza query allo scroll',
    (tester) async {
      final repository = _LongRepository();
      final cubit = ServiceRequestsCubit(GetServiceRequests(repository))
        ..load();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: MechanicShellGeometry(
            controlsBottom: 12,
            child: BlocProvider.value(
              value: cubit,
              child: const ServiceRequestsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Veicolo 29'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Veicolo 29'),
        600,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Veicolo 29'), findsOneWidget);
      expect(repository.calls, 1);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
    },
  );
  testWidgets('mostra richieste, costi e azione esegui', (tester) async {
    final cubit = ServiceRequestsCubit(GetServiceRequests(_FakeRepository()))
      ..load();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: MechanicShellGeometry(
          controlsBottom: 12,
          child: BlocProvider.value(
            value: cubit,
            child: const ServiceRequestsPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Richieste di intervento'), findsOneWidget);
    expect(find.text('Alfa Romeo Mito'), findsOneWidget);
    expect(find.text('DT 512 FD'), findsOneWidget);
    expect(find.text('Cambio pastiglie posteriori'), findsOneWidget);
    expect(find.text('€ 180'), findsOneWidget);

    final start = tester.getCenter(
      find.byKey(const ValueKey('request-timeline-start')),
    );
    final connector = tester.getCenter(
      find.byKey(const ValueKey('request-timeline-connector')),
    );
    final firstNode = tester.getCenter(
      find.byKey(const ValueKey('request-timeline-node-0')),
    );
    final secondNode = tester.getCenter(
      find.byKey(const ValueKey('request-timeline-node-1')),
    );
    expect(connector.dx, closeTo(start.dx, 0.01));
    expect(firstNode.dx, closeTo(start.dx, 0.01));
    expect(secondNode.dx, closeTo(start.dx, 0.01));
    expect(firstNode.dy, greaterThan(start.dy));
    expect(secondNode.dy, greaterThan(firstNode.dy));

    await tester.tap(find.byKey(const ValueKey('execute-request-1')));
    await tester.pump();
    expect(
      find.text('Apertura intervento per Alfa Romeo Mito'),
      findsOneWidget,
    );
  });
}

class _FakeRepository implements ServiceRequestRepository {
  @override
  Future<List<ServiceRequest>> getRequests() async => requests;

  static final requests = <ServiceRequest>[
    ServiceRequest(
      id: 'request-1',
      vehicleModel: 'Alfa Romeo Mito',
      plate: 'DT 512 FD',
      issues: const ['Cambio pastiglie posteriori', 'Controllo dischi'],
      estimatedCost: 180,
      registeredAt: DateTime(2026, 9, 1),
      reminderDate: DateTime(2026, 9, 30),
    ),
  ];
}

class _LongRepository implements ServiceRequestRepository {
  int calls = 0;
  @override
  Future<List<ServiceRequest>> getRequests() async {
    calls++;
    return List.generate(
      30,
      (i) => ServiceRequest(
        id: 'item-$i',
        vehicleModel: 'Veicolo $i',
        plate: 'AA123BB',
        issues: const ['Controllo'],
        registeredAt: DateTime(2026, 9, 1),
        reminderDate: DateTime(2026, 9, 30),
      ),
    );
  }
}
