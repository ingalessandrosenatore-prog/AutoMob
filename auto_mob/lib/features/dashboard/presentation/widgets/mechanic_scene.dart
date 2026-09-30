import 'package:flutter_scene/scene.dart';

/// Render-resource owner for the single-character preview, not a data service.
class MechanicScene {
  MechanicScene._(this.scene, this.assetPath);

  final Scene scene;
  final String assetPath;

  static Future<MechanicScene> load(String assetPath) async {
    await Scene.initializeStaticResources();
    final model = await loadScene(assetPath);
    // The GLB includes both poses and all tools. Show only one combination.
    model.getChildByName('AM_DESK')?.visible = false;
    model.getChildByName('AM_STANDING')?.visible = true;
    for (final prop in ['wrench', 'screwdriver', 'tablet', 'tire']) {
      model.getChildByName('standing_PROP_$prop')?.visible = prop == 'wrench';
    }
    return MechanicScene._(Scene()..add(model), assetPath);
  }

  Future<void> release() async {
    await releaseScene(assetPath);
  }
}
