import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // The app keeps its GLB under lib/assets, not the default assets/.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      discoveryRoot: 'lib/assets/mascot/',
    );
  });
}
