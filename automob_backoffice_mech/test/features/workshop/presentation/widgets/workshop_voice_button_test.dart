import 'package:automob_backoffice_mech/features/workshop/presentation/bloc/voice_search_state.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_voice_button.dart';
import 'package:automob_backoffice_mech/features/workshop/presentation/widgets/workshop_voice_glow_painter.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('usa colors.info e ampiezza voce solo durante l ascolto', (
    tester,
  ) async {
    Future<void> pumpVoice(VoiceSearchState state) => tester.pumpWidget(
      MaterialApp(
        theme: AmTheme.dark,
        home: Center(
          child: SizedBox.square(
            dimension: 68,
            child: WorkshopVoiceButton(state: state, onPressed: () {}),
          ),
        ),
      ),
    );

    await pumpVoice(const VoiceSearchState());
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('workshop_voice_glow')),
          )
          .opacity,
      0,
    );

    const amplitude = 0.72;
    await pumpVoice(
      const VoiceSearchState(
        status: VoiceSearchStatus.listening,
        amplitude: amplitude,
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('workshop_voice_glow_paint')),
    );
    final painter = paint.painter! as WorkshopVoiceGlowPainter;
    final colors = AmThemeColors.of(
      tester.element(find.byKey(const ValueKey('workshop_voice_glow_paint'))),
    );

    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('workshop_voice_glow')),
          )
          .opacity,
      1,
    );
    expect(find.byType(ClipOval), findsOneWidget);
    expect(painter.color, colors.info);
    expect(painter.amplitude, amplitude);
  });

  test('ridisegna il glow quando cambia l ampiezza della voce', () {
    const quiet = WorkshopVoiceGlowPainter(
      color: Colors.blue,
      phase: 0.2,
      amplitude: 0.1,
    );
    const loud = WorkshopVoiceGlowPainter(
      color: Colors.blue,
      phase: 0.2,
      amplitude: 0.9,
    );

    expect(loud.shouldRepaint(quiet), isTrue);
  });
}
