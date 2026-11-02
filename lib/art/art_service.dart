import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/comic.dart';
import 'cutout.dart';

/// A Digimon's artwork as a die-cut sticker (background removed, white rim
/// baked in) plus the comic swatch picked from its colours.
class DigiArt {
  final Uint8List stickerPng;

  /// Index into [Comic.swatches], or null when the art has no strong colour.
  final int? swatch;

  const DigiArt(this.stickerPng, this.swatch);

  Color colorFor(int id) => swatch == null ? Comic.forId(id) : Comic.swatches[swatch!];
}

/// Does the pixel work for one image. Top-level so it can run in an isolate.
({Uint8List png, int? swatch})? processArt(Uint8List bytes) {
  final cut = Cutout.decode(bytes);
  if (cut == null) return null;
  final swatch = ComicColor.swatchIndex(cut.rgba);
  // A 4px rim on 320px art: ~3px on the detail hero, ~1px on the small cards.
  final rim = (cut.width / 80).round().clamp(2, 8);
  final sticker = Cutout.sticker(cut.rgba, cut.width, cut.height, rim: rim);
  return (png: Cutout.encodePng(sticker.rgba, sticker.width, sticker.height), swatch: swatch);
}

// Top-level so the closure sent to the isolate captures nothing but the bytes.
Future<({Uint8List png, int? swatch})?> _processInIsolate(Uint8List bytes) => Isolate.run(() => processArt(bytes));

abstract class ArtService {
  /// Art that's already in memory, so it can be drawn without a frame of placeholder.
  DigiArt? cached(String url);

  /// The processed art, or null if it can't be made (show the original instead).
  Future<DigiArt?> load(String url);
}

/// Used in tests and anywhere art processing isn't available: always falls
/// back to the original image.
class NoArtService implements ArtService {
  const NoArtService();

  @override
  DigiArt? cached(String url) => null;

  @override
  Future<DigiArt?> load(String url) async => null;
}

class CutoutArtService implements ArtService {
  /// Bump when the algorithm changes, so old cache files are ignored.
  static const int cacheVersion = 1;
  static const int _memoryEntries = 150;
  static const int _maxParallel = 2;

  final Dio _dio;
  final LinkedHashMap<String, DigiArt> _memory = LinkedHashMap();
  final Map<String, Future<DigiArt?>> _inFlight = {};
  final Queue<Completer<void>> _waiting = Queue();
  int _running = 0;
  Future<Directory?>? _dir;

  CutoutArtService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 20)));

  @override
  DigiArt? cached(String url) {
    final art = _memory.remove(url);
    if (art != null) _memory[url] = art; // most recently used goes last
    return art;
  }

  @override
  Future<DigiArt?> load(String url) {
    final hit = cached(url);
    if (hit != null) return Future.value(hit);
    // Never leave a card blank: after this long, show the original image.
    // The callback must not return the removed future: whenComplete would wait
    // for it, i.e. for itself, and never finish.
    return _inFlight.putIfAbsent(url, () => _load(url).timeout(const Duration(seconds: 30), onTimeout: () => null).whenComplete(() {
          _inFlight.remove(url);
        }));
  }

  Future<DigiArt?> _load(String url) async {
    try {
      final file = await _cacheFile(url);
      if (file != null) {
        final fromDisk = await _readCache(file);
        if (fromDisk != null) return _remember(url, fromDisk);
      }

      final response = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data ?? const []);
      if (bytes.isEmpty) return null;

      final result = await _limited(() => _processInIsolate(bytes));
      if (result == null) return null;
      final art = DigiArt(result.png, result.swatch);
      if (file != null) unawaited(_writeCache(file, art));
      return _remember(url, art);
    } catch (_) {
      return null;
    }
  }

  DigiArt _remember(String url, DigiArt art) {
    _memory[url] = art;
    while (_memory.length > _memoryEntries) {
      _memory.remove(_memory.keys.first);
    }
    return art;
  }

  /// Runs at most [_maxParallel] isolates at once so scrolling stays smooth.
  Future<T> _limited<T>(Future<T> Function() task) async {
    if (_running >= _maxParallel) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    }
    _running++;
    try {
      return await task();
    } finally {
      _running--;
      if (_waiting.isNotEmpty) _waiting.removeFirst().complete();
    }
  }

  Future<File?> _cacheFile(String url) async {
    final dir = await (_dir ??= _openDir());
    if (dir == null) return null;
    final key = sha1.convert(utf8.encode(url)).toString();
    return File('${dir.path}${Platform.pathSeparator}$key.png');
  }

  Future<Directory?> _openDir() async {
    try {
      // If the platform never answers, cache in memory only.
      final base = await getApplicationCacheDirectory().timeout(const Duration(seconds: 3));
      return await Directory('${base.path}${Platform.pathSeparator}cutouts-v$cacheVersion').create(recursive: true);
    } catch (_) {
      return null; // no disk cache, memory only
    }
  }

  // The swatch is stored in a one-line sidecar file next to the PNG.
  Future<DigiArt?> _readCache(File png) async {
    try {
      if (!await png.exists()) return null;
      final meta = File('${png.path}.swatch');
      final swatch = await meta.exists() ? int.tryParse((await meta.readAsString()).trim()) : null;
      return DigiArt(await png.readAsBytes(), swatch);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(File png, DigiArt art) async {
    try {
      await File('${png.path}.swatch').writeAsString('${art.swatch ?? ''}');
      await png.writeAsBytes(art.stickerPng, flush: true);
    } catch (_) {}
  }
}
