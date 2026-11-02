import 'dart:typed_data';

import 'package:digidexplus/art/art_service.dart';
import 'package:image/image.dart' as img;

/// Serves the same tiny transparent sticker for every url, so widget tests go
/// through the real sticker path without network or isolates.
class FakeArtService implements ArtService {
  static final Uint8List _png = img.encodePng(img.Image(width: 4, height: 4, numChannels: 4));

  final DigiArt art = DigiArt(_png, 1);

  @override
  DigiArt? cached(String url) => art;

  @override
  Future<DigiArt?> load(String url) async => art;
}
