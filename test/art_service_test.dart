import 'dart:typed_data';

import 'package:digidexplus/art/art_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Answers every request with [body] and counts requests.
class _FakeAdapter implements HttpClientAdapter {
  final Uint8List body;
  int requests = 0;

  _FakeAdapter(this.body);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ResponseBody.fromBytes(body, 200, headers: {
      Headers.contentTypeHeader: ['image/png'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Uint8List _whiteBackgroundPng() {
  final image = img.Image(width: 24, height: 24);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  img.fillCircle(image, x: 12, y: 12, radius: 6, color: img.ColorRgb8(40, 160, 240));
  return img.encodePng(image);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CutoutArtService', () {
    late _FakeAdapter adapter;
    late CutoutArtService service;

    setUp(() {
      adapter = _FakeAdapter(_whiteBackgroundPng());
      service = CutoutArtService(dio: Dio(BaseOptions(responseType: ResponseType.bytes))..httpClientAdapter = adapter);
    });

    test('load completes, and concurrent loads share one download', () async {
      const url = 'https://example.com/a.png';
      // Before the fix, a load still in flight never completed.
      final results = await Future.wait([service.load(url), service.load(url)]).timeout(const Duration(seconds: 10));

      expect(results[0], isNotNull);
      expect(results[1], same(results[0]));
      expect(results[0]!.swatch, 1, reason: 'blue');
      expect(adapter.requests, 1);
    });

    test('a finished load is served from memory, and a new load works after it', () async {
      const url = 'https://example.com/b.png';
      final first = await service.load(url).timeout(const Duration(seconds: 10));
      expect(service.cached(url), same(first));
      expect(await service.load(url).timeout(const Duration(seconds: 10)), same(first));
      expect(adapter.requests, 1);

      expect(await service.load('https://example.com/c.png').timeout(const Duration(seconds: 10)), isNotNull);
      expect(adapter.requests, 2);
    });

    test('bytes that are not an image give null (the UI shows the original)', () async {
      final bad = CutoutArtService(dio: Dio()..httpClientAdapter = _FakeAdapter(Uint8List.fromList([1, 2, 3])));
      expect(await bad.load('https://example.com/bad.png').timeout(const Duration(seconds: 10)), isNull);
    });
  });
}
