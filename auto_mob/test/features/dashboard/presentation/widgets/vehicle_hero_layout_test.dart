import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_card_pose.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_callouts.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_connectors.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_layout.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_stage.dart';
import 'package:auto_mob_v1/features/dashboard/presentation/widgets/vehicle_hero/vehicle_hero_scene.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/maintenance_kpi.dart';
import 'package:auto_mob_v1/features/vehicle/domain/entities/vehicle_maintenance_setting.dart';
import 'package:common_ui_widget/common_ui_widget.dart' show AmTheme;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

const _kpis = [
  MaintenanceKpi(
    type: EnumPopUp.aggiornaTagliando,
    remainingKm: 7000,
    percentage: 70,
    components: [
      MaintenanceComponentKpi(label: 'Filtro aria', percentage: 75),
      MaintenanceComponentKpi(label: 'Candele', percentage: 65),
    ],
  ),
  MaintenanceKpi(
    type: EnumPopUp.aggiornaDistribuzione,
    remainingKm: 14000,
    percentage: 90,
  ),
  MaintenanceKpi(
    type: EnumPopUp.altro,
    group: VehicleMaintenanceGroup.brakes,
    remainingKm: 0,
    percentage: 75,
    components: [
      MaintenanceComponentKpi(
        label: 'Pastiglie',
        percentage: 50,
        parts: [
          MaintenanceComponentKpi(label: 'Anteriori', percentage: 100),
          MaintenanceComponentKpi(label: 'Posteriori', percentage: 0),
        ],
      ),
      MaintenanceComponentKpi(label: 'Liquido freni', percentage: 100),
    ],
  ),
  MaintenanceKpi(
    type: EnumPopUp.altro,
    group: VehicleMaintenanceGroup.gearbox,
    remainingKm: 9000,
    percentage: 60,
    components: [
      MaintenanceComponentKpi(label: 'Olio cambio', percentage: 90),
      MaintenanceComponentKpi(label: 'Olio differenziale', percentage: 30),
    ],
  ),
  MaintenanceKpi(
    type: EnumPopUp.altro,
    group: VehicleMaintenanceGroup.lpg,
    remainingKm: 9000,
    percentage: 90,
  ),
  MaintenanceKpi(
    type: EnumPopUp.aggiornaCambioGomme,
    remainingKm: 3000,
    percentage: 20,
  ),
  MaintenanceKpi(
    type: EnumPopUp.pneumaticiInversione,
    remainingKm: 1000,
    percentage: 40,
  ),
];

void main() {
  test(
    'il gruppo posteriore ha un aggancio comune e Gomme usa la ruota posteriore',
    () {
      final cards = VehicleHeroCallout.forKpis(_kpis);
      expect(
        cards.where((card) => card.isRear).map((card) => card.anchor).toSet(),
        {'fuel_tank'},
      );
      expect(cards.singleWhere((card) => card.isTires).anchor, 'tire_RL');
      expect(cards.singleWhere((card) => card.title == 'Trasmissione').meshes, [
        'gearbox',
        'differential',
      ]);
      expect(
        cards.singleWhere((card) => card.title == 'Freni').anchor,
        'brake_disc_FL',
      );
    },
  );

  test(
    'la card si muove con la camera e torna leggibile nella posa di riposo',
    () {
      final orbit = VehicleHeroOrbit(Vector3(0, .6, 0), 6.6);
      const viewport = Rect.fromLTWH(12, 44, 340, 220);
      const rest = Rect.fromLTWH(224, 12, 128, 60);
      final pose = VehicleHeroCardPose(
        rest: rest.translate(3, 8),
        rearRest: rest,
        viewport: viewport,
        rear: true,
        keepsFocus: false,
        backgroundOpacity: .20,
        anchor: Vector3(-.95, .28, .3),
        frontCamera: orbit.cameraAt(0),
        rearCamera: orbit.cameraAt(1),
      );
      final base = pose.at(
        camera: orbit.cameraAt(0),
        position: 0,
        hasRear: true,
        stageWidth: 364,
      );
      final middle = pose.at(
        camera: orbit.cameraAt(.58),
        position: .58,
        hasRear: true,
        stageWidth: 364,
      );
      final end = pose.at(
        camera: orbit.cameraAt(1),
        position: 1,
        hasRear: true,
        stageWidth: 364,
      );
      expect(base.origin, isNot(end.origin));
      expect(base.rect.center, isNot(end.rect.center));
      expect(base.opacity, .20);
      expect(base.rect.center.dx, lessThan(364));
      expect(middle.opacity, greaterThan(base.opacity));
      expect(middle.scale, lessThan(end.scale));
      expect(end.opacity, 1);
      expect((end.rect.center - rest.center).distance, lessThan(.01));
    },
  );

  test(
    'la curva resta attaccata alla card e non si allunga durante la rotazione',
    () {
      final orbit = VehicleHeroOrbit(Vector3(0, .6, 0), 6.6);
      final pose = VehicleHeroCardPose(
        rest: const Rect.fromLTWH(12, 12, 160, 65),
        rearRest: null,
        viewport: const Rect.fromLTWH(12, 44, 340, 220),
        rear: false,
        keepsFocus: false,
        backgroundOpacity: .09,
        anchor: Vector3(1.34, .77, .48),
        frontCamera: orbit.cameraAt(0),
        rearCamera: orbit.cameraAt(1),
        wireEdge: VehicleHeroWireEdge.bottom,
      );
      final front = pose.at(
        camera: orbit.cameraAt(0),
        position: 0,
        hasRear: true,
        stageWidth: 364,
      );
      final maxLength = VehicleHeroConnector.length(front.origin!, front.end!);
      for (var step = 1; step <= 20; step++) {
        final progress = step / 20;
        final frame = pose.at(
          camera: orbit.cameraAt(progress),
          position: progress,
          hasRear: true,
          stageWidth: 364,
        );
        final edge =
            frame.rect.center + Offset(0, frame.rect.height * frame.scale / 2);
        expect((frame.end! - edge).distance, lessThan(.001));
        expect(
          VehicleHeroConnector.length(frame.origin!, frame.end!),
          lessThanOrEqualTo(maxLength + .25),
        );
      }
    },
  );

  test(
    'Freni scende vicino alla ruota e il gruppo posteriore resta in scena',
    () {
      final cards = VehicleHeroCallout.forKpis(_kpis);
      expect(cards.map((card) => card.title), [
        'Tagliando',
        'Distribuzione',
        'Freni',
        'Trasmissione',
        'Impianto GPL',
        'Gomme',
      ]);
      for (final width in [240.0, 320.0, 420.0]) {
        final layout = VehicleHeroLayout(
          width: width,
          items: [for (final card in cards) (slot: card.slot, height: 65)],
        );
        expect(layout.cards[0].center.dx, lessThan(width / 2));
        expect(layout.cards[1].top, lessThan(layout.cards[0].top));
        expect(layout.cards[2].center.dx, greaterThan(width / 2));
        expect(layout.cards[2].top, greaterThan(layout.viewport.center.dy));
        expect(layout.rearCards[2].center.dx, lessThan(width / 2));
        expect(layout.cards[3].top, lessThan(layout.cards[2].top));
        expect(layout.rearCards[4].bottom, lessThan(layout.rearCards[5].top));
        expect(layout.cards[5].top - layout.cards[2].bottom, 8);
        for (final card in [...layout.cards, ...layout.rearCards]) {
          expect(card.left, greaterThanOrEqualTo(0));
          expect(card.right, lessThanOrEqualTo(width));
          expect(card.bottom, lessThanOrEqualTo(layout.height));
        }
      }
    },
  );

  testWidgets(
    'Freni e Gomme usano le stesse righe e Inversione resta apribile',
    (tester) async {
      MaintenanceKpi? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: AmTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: VehicleHeroStage(
                scene: null,
                loading: false,
                callouts: VehicleHeroCallout.forKpis(_kpis),
                onKpiTap: (kpi) => opened = kpi,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Candele'), findsOneWidget);
      expect(find.text('Motore'), findsNothing);
      expect(find.text('Pastiglie'), findsOneWidget);
      expect(find.text('Anteriori'), findsNothing);
      expect(find.text('Posteriori'), findsNothing);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      final tires = VehicleHeroCallout.forKpis(
        _kpis,
      ).singleWhere((card) => card.isTires);
      expect(tires.kpi.percentage, 30);
      expect(find.text('Pneumatici'), findsOneWidget);
      expect(find.text('Inversione'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      await tester.ensureVisible(find.text('Inversione'));
      await tester.tap(find.text('Inversione'));
      expect(opened?.type, EnumPopUp.pneumaticiInversione);
      expect(tester.takeException(), isNull);
    },
  );
}
