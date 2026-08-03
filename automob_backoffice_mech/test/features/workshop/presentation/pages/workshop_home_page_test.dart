import 'package:automob_backoffice_mech/core/widgets/mechanic_shapes.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_bloc.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_event.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_state.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/pages/workshop_home_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:soft_edge_blur/soft_edge_blur.dart';

final class _MockWorkshopBloc extends MockBloc<WorkshopEvent, WorkshopState>
    implements WorkshopBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const WorkshopSearchChanged('')));

  testWidgets('mostra dati sessione, liquid glass e stato vuoto', (
    tester,
  ) async {
    final bloc = _MockWorkshopBloc();
    when(() => bloc.state).thenReturn(_ready());

    await _pump(tester, bloc: bloc);

    expect(find.text('Buon lavoro,'), findsOneWidget);
    expect(find.text('Marco'), findsOneWidget);
    expect(find.text('I tuoi clienti'), findsOneWidget);
    expect(find.text('0 totali'), findsOneWidget);
    expect(
      find.text('Non hai veicoli collegati alla tua officina'),
      findsOneWidget,
    );
    expect(find.byType(OCLiquidGlass), findsAtLeastNWidgets(3));
    expect(find.byType(SoftEdgeBlur), findsOneWidget);
    final softEdgeBlur = tester.widget<SoftEdgeBlur>(find.byType(SoftEdgeBlur));
    expect(softEdgeBlur.edges.map((edge) => edge.type), [
      EdgeType.topEdge,
      EdgeType.bottomEdge,
    ]);
    expect(softEdgeBlur.edges.map((edge) => edge.size), [72, 92]);
    expect(softEdgeBlur.edges.map((edge) => edge.sigma), everyElement(10));
    expect(find.byType(SafeArea), findsNothing);
    expect(tester.getSize(find.byTooltip('Impostazioni')), const Size(48, 48));
    expect(mechanicMinimumTouchTarget, 48);
    expect(tester.getSize(find.byType(TextField)).height, 56);
  });

  testWidgets('renderizza status blu/arancione e abilita la ricerca', (
    tester,
  ) async {
    final bloc = _MockWorkshopBloc();
    when(() => bloc.state).thenReturn(
      _ready(
        vehicles: [
          _vehicle(id: 'due', due: true),
          _vehicle(id: 'ok', brand: 'Alfa'),
        ],
      ),
    );

    await _pump(tester, bloc: bloc);
    await tester.enterText(find.byType(TextField), 'panda AB-123-CD');

    expect(find.byType(MechanicVehicleCard), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField)).onChanged,
      isNotNull,
    );
    expect(find.byTooltip('Filtri non ancora disponibili'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.tune_rounded),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'la riga ricerca sale insieme alla tastiera con AnimatedPositioned',
    (tester) async {
      final bloc = _MockWorkshopBloc();
      when(() => bloc.state).thenReturn(_ready());
      await _pump(tester, bloc: bloc);
      final row = find.byKey(const ValueKey('workshop_search_row'));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      await tester.pump();

      final positioned = tester.widget<AnimatedPositioned>(row);
      expect(positioned.bottom, 14 + (300 / tester.view.devicePixelRatio));
      expect(positioned.duration, const Duration(milliseconds: 240));
    },
  );

  testWidgets('un errore di caricamento apre il popup con Riprova', (
    tester,
  ) async {
    final bloc = _MockWorkshopBloc();
    whenListen(
      bloc,
      Stream<WorkshopState>.fromIterable(const [
        WorkshopLoading(),
        WorkshopLoadFailure('Connessione assente.'),
      ]),
      initialState: const WorkshopLoading(),
    );

    await _pump(tester, bloc: bloc);
    await tester.pumpAndSettle();

    expect(find.text('Impossibile caricare i veicoli'), findsOneWidget);
    expect(find.text('Connessione assente.'), findsOneWidget);
    expect(find.text('Riprova'), findsAtLeastNWidgets(1));
  });
}

Future<void> _pump(WidgetTester tester, {required WorkshopBloc bloc}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: BlocProvider.value(value: bloc, child: const WorkshopHomePage()),
      ),
    );

WorkshopReady _ready({List<WorkshopVehicle> vehicles = const []}) =>
    WorkshopReady(
      mechanic: const WorkshopMechanic(displayName: 'Marco'),
      allVehicles: vehicles,
      filteredVehicles: vehicles,
      query: '',
      visibleCount: 20,
    );

WorkshopVehicle _vehicle({
  required String id,
  String brand = 'Fiat',
  bool due = false,
}) => WorkshopVehicle(
  id: id,
  plate: 'AB123CD',
  brand: brand,
  model: 'Panda',
  year: 2022,
  kmCurrent: 124000,
  tagliandoIntervalKm: 15000,
  requiresMaintenance: due,
);
