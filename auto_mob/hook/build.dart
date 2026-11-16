import 'package:flutter_scene/build_hooks.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    // The workshop and vehicle GLBs share the app's Scene asset pipeline.
    buildScenes(
      buildInput: input,
      buildOutput: output,
      discoveryRoot: 'lib/assets/',
    );
  });
}
