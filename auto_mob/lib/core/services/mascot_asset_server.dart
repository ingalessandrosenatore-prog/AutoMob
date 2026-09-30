import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Serves only the bundled mascot files to a local WebView origin.
/// An HTTP origin lets the GLB loader fetch its sibling asset on both iOS and
/// Android without enabling broad file access inside the WebView.
class MascotAssetServer {
  HttpServer? _server;

  String? get url => _server == null
      ? null
      : 'http://127.0.0.1:${_server!.port}/carousel.html';

  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(_serve(server));
  }

  Future<void> _serve(HttpServer server) async {
    const assets = {
      '/carousel.html': ('carousel.html', 'text/html; charset=utf-8'),
      '/carousel.js': ('carousel.js', 'text/javascript; charset=utf-8'),
      '/automob_mascot.glb': ('automob_mascot.glb', 'model/gltf-binary'),
      '/manifest.json': ('manifest.json', 'application/json'),
    };
    await for (final request in server) {
      final asset = assets[request.uri.path];
      if (request.method != 'GET' || asset == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }
      try {
        final bytes = await rootBundle.load('lib/assets/mascot/${asset.$1}');
        request.response.headers.contentType = ContentType.parse(asset.$2);
        request.response.headers.set('Cache-Control', 'public, max-age=3600');
        request.response.add(bytes.buffer.asUint8List());
      } catch (_) {
        request.response.statusCode = HttpStatus.internalServerError;
      }
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
