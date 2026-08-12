import 'dart:async';

import 'package:automob_backoffice_mech/core/widgets/mechanic_shapes.dart';
import 'package:automob_backoffice_mech/core/widgets/mechanic_vehicle_card.dart';
import 'package:automob_backoffice_mech/core/router/mechanic_shell_metrics.dart';
import 'package:automob_backoffice_mech/features/workshop/domain/entities/workshop_catalog.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_bloc.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_event.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_state.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/workshop_vehicle_filter.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_bloc.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_event.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_state.dart';
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

final class _MockVoiceSearchBloc
    extends MockBloc<VoiceSearchEvent, VoiceSearchState>
    implements VoiceSearchBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const WorkshopSearchChanged('')));
  setUpAll(() => registerFallbackValue(const VoiceSearchStarted()));

  testWidgets('mostra dati sessione, superfici graduate e stato vuoto', (
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
    expect(find.byType(DecoratedBox), findsAtLeastNWidgets(3));
    expect(find.byType(SoftEdgeBlur), findsNothing);
    expect(find.byKey(const ValueKey('workshop_edge_blur')), findsOneWidget);
    expect(find.byType(SafeArea), findsNothing);
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(const ValueKey('workshop_app_bar')),
          matching: find.byType(InkWell),
        ),
      ),
      const Size(48, 48),
    );
    expect(mechanicMinimumTouchTarget, 48);
    expect(
      tester.getSize(find.byKey(const ValueKey('workshop_search_row'))).height,
      MechanicShellMetrics.searchHeight,
    );
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
    expect(find.byTooltip('Filtra veicoli'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MechanicVehicleCard),
        matching: find.byType(InkWell),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('il menu filtro invia la selezione al WorkshopBloc', (
    tester,
  ) async {
    final bloc = _MockWorkshopBloc();
    when(
      () => bloc.state,
    ).thenReturn(_ready(vehicles: [_vehicle(id: 'due', due: true)]));

    await _pump(tester, bloc: bloc);
    final button = tester.widget<PopupMenuButton<WorkshopVehicleFilter>>(
      find.byKey(const ValueKey('workshop_filter_button')),
    );
    button.onSelected!(WorkshopVehicleFilter.maintenanceDue);
    await tester.pump();

    verify(
      () => bloc.add(
        any(
          that: isA<WorkshopVehicleFilterChanged>().having(
            (event) => event.filter,
            'filter',
            WorkshopVehicleFilter.maintenanceDue,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('allinea microfono alla navigation e ricerca subito sopra', (
    tester,
  ) async {
    final bloc = _MockWorkshopBloc();
    when(() => bloc.state).thenReturn(_ready());
    const physicalBottomInset = 24.0;
    await _pump(
      tester,
      bloc: bloc,
      shellControlsBottom: physicalBottomInset,
      mediaQueryData: const MediaQueryData(
        padding: EdgeInsets.only(bottom: 104),
        viewPadding: EdgeInsets.only(bottom: physicalBottomInset),
      ),
    );

    final microphone = tester.widget<Positioned>(
      find.byKey(const ValueKey('workshop_voice_button')),
    );
    final search = tester.widget<Positioned>(
      find.byKey(const ValueKey('workshop_search_row')),
    );

    expect(microphone.bottom, physicalBottomInset);
    expect(
      search.bottom,
      physicalBottomInset +
          MechanicShellMetrics.navigationHeight +
          MechanicShellMetrics.searchNavigationGap,
    );
  });

  testWidgets(
    'la riga ricerca sale insieme alla tastiera con repaint del liquid glass',
    (tester) async {
      final bloc = _MockWorkshopBloc();
      when(() => bloc.state).thenReturn(_ready());
      await _pump(tester, bloc: bloc);
      final row = find.byKey(const ValueKey('workshop_search_row'));

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 240));

      final positioned = tester.widget<Positioned>(row);
      expect(positioned.bottom, 12 + (300 / tester.view.devicePixelRatio));
      expect(
        tester
            .widget<OCLiquidGlassGroup>(
              find.descendant(
                of: row,
                matching: find.byType(OCLiquidGlassGroup),
              ),
            )
            .repaint,
        isA<Listenable>(),
      );
    },
  );

  testWidgets('il microfono avvia la ricerca vocale senza overlay', (
    tester,
  ) async {
    final workshopBloc = _MockWorkshopBloc();
    when(() => workshopBloc.state).thenReturn(_ready());
    final voiceBloc = _MockVoiceSearchBloc();
    final voiceStates = StreamController<VoiceSearchState>();
    addTearDown(voiceStates.close);
    whenListen(
      voiceBloc,
      voiceStates.stream,
      initialState: const VoiceSearchState(),
    );

    await _pump(tester, bloc: workshopBloc, voiceBloc: voiceBloc);
    await tester.tap(find.byKey(const ValueKey('workshop_voice_button')));
    await tester.pump();

    verify(() => voiceBloc.add(any(that: isA<VoiceSearchStarted>()))).called(1);

    voiceStates.add(
      const VoiceSearchState(status: VoiceSearchStatus.listening),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('workshop_voice_glow')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workshop_voice_button')));
    verify(() => voiceBloc.add(any(that: isA<VoiceSearchStopped>()))).called(1);

    voiceStates.add(const VoiceSearchState(status: VoiceSearchStatus.failure));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workshop_voice_button')));
    verify(
      () => voiceBloc.add(any(that: isA<VoiceSearchDismissed>())),
    ).called(1);
  });

  testWidgets('la trascrizione parziale aggiorna input e filtro lista', (
    tester,
  ) async {
    final workshopBloc = _MockWorkshopBloc();
    when(
      () => workshopBloc.state,
    ).thenReturn(_ready(vehicles: [_vehicle(id: 'fiat')]));
    final voiceBloc = _MockVoiceSearchBloc();
    whenListen(
      voiceBloc,
      Stream<VoiceSearchState>.fromIterable(const [
        VoiceSearchState(
          status: VoiceSearchStatus.listening,
          transcript: 'fiat punto',
          amplitude: 0.6,
        ),
      ]),
      initialState: const VoiceSearchState(),
    );

    await _pump(tester, bloc: workshopBloc, voiceBloc: voiceBloc);
    await tester.pump();

    expect(find.text('fiat punto'), findsOneWidget);
    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.controller!.text, 'fiat punto');
    expect(
      searchField.controller!.selection,
      const TextSelection.collapsed(offset: 10),
    );
    verify(
      () => workshopBloc.add(
        any(
          that: isA<WorkshopSearchChanged>().having(
            (event) => event.query,
            'query',
            'fiat punto',
          ),
        ),
      ),
    ).called(1);
  });

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

Future<void> _pump(
  WidgetTester tester, {
  required WorkshopBloc bloc,
  VoiceSearchBloc? voiceBloc,
  MediaQueryData? mediaQueryData,
  double shellControlsBottom = MechanicShellMetrics.bottomMargin,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AmTheme.dark,
    home: Builder(
      builder: (context) => MediaQuery(
        data: mediaQueryData ?? MediaQuery.of(context),
        child: MechanicShellGeometry(
          controlsBottom: shellControlsBottom,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: bloc),
              BlocProvider.value(value: voiceBloc ?? _idleVoiceSearchBloc()),
            ],
            child: const WorkshopHomePage(),
          ),
        ),
      ),
    ),
  ),
);

VoiceSearchBloc _idleVoiceSearchBloc() {
  final bloc = _MockVoiceSearchBloc();
  when(() => bloc.state).thenReturn(const VoiceSearchState());
  return bloc;
}

WorkshopReady _ready({List<WorkshopVehicle> vehicles = const []}) =>
    WorkshopReady(
      mechanic: const WorkshopMechanic(displayName: 'Marco'),
      allVehicles: vehicles,
      filteredVehicles: vehicles,
      query: '',
      filter: WorkshopVehicleFilter.all,
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
