import 'package:flutter_scene/scene.dart';

/// One template for this carousel's lifetime, not one GPU model per vehicle.
/// Actor clones share its geometry; disposal returns the package's cache claim.
class MechanicModelCache {
  MechanicModelCache(
    this.assetPath, {
    Future<Node> Function(String) loader = _load,
    Future<void> Function(String) releaser = _release,
  }) : _loader = loader,
       _releaser = releaser;

  final String assetPath;
  final Future<Node> Function(String) _loader;
  final Future<void> Function(String) _releaser;
  Future<Node>? _pending;
  Future<void>? _disposal;
  bool _disposed = false;

  Future<Node> load() {
    if (_disposed) throw StateError('Model cache already disposed');
    return _pending ??= _loader(assetPath).then(
      (node) => node,
      onError: (Object error, StackTrace stack) {
        _pending = null;
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  Future<void> dispose() {
    _disposed = true;
    return _disposal ??= _releasePending();
  }

  Future<void> _releasePending() async {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    try {
      await pending;
    } catch (_) {
      // A failed load never acquired a template claim to release.
      return;
    }
    await _releaser(assetPath);
  }

  static Future<Node> _load(String path) async {
    await Scene.initializeStaticResources();
    return loadScene(path);
  }

  static Future<void> _release(String path) async {
    await releaseScene(path);
  }
}
