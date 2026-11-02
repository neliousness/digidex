import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/comic.dart';
import 'art_service.dart';

/// A Digimon's art as a die-cut sticker: background removed, white rim baked
/// in, with a hard ink drop shadow drawn here.
///
/// Until the cut-out is ready nothing is drawn (the white-box original looks
/// worse on coloured cards than a brief gap); if it can't be made, the
/// original image is shown instead.
class StickerArt extends StatefulWidget {
  final String? url;
  final double size;
  final double shadow;

  /// Called once the art (and its colour) is known.
  final ValueChanged<DigiArt>? onArt;

  const StickerArt({super.key, required this.url, required this.size, this.shadow = 5, this.onArt});

  @override
  State<StickerArt> createState() => _StickerArtState();
}

class _StickerArtState extends State<StickerArt> {
  DigiArt? _art;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StickerArt old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _art = null;
      _failed = false;
      _resolve();
    }
  }

  void _resolve() {
    final url = widget.url;
    if (url == null) {
      _failed = true;
      return;
    }
    final service = context.read<ArtService>();
    final cached = service.cached(url);
    if (cached != null) {
      _art = cached;
      widget.onArt?.call(cached);
      return;
    }
    service.load(url).then((art) {
      if (!mounted || widget.url != url) return;
      setState(() {
        _art = art;
        _failed = art == null;
      });
      if (art != null) widget.onArt?.call(art);
    });
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    Widget child;
    if (art != null) {
      final cacheWidth = (widget.size * MediaQuery.devicePixelRatioOf(context)).round();
      final fade = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 260);
      // The shadow is the same image tinted ink at paint time (no extra layer).
      Image image({Color? tint}) => Image.memory(art.stickerPng,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcIn,
          // Fade in once decoded, rather than popping in; art already on
          // screen (decoded synchronously) shows at once.
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
              ? child
              : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: fade, curve: Curves.easeOut, child: child),
          // If the sticker can't be drawn, show the original art instead.
          errorBuilder: (context, error, stack) {
            return tint != null || widget.url == null ? const SizedBox.shrink() : CachedNetworkImage(imageUrl: widget.url!, width: widget.size, height: widget.size, fit: BoxFit.contain);
          });
      child = Stack(
        key: const ValueKey('art'),
        clipBehavior: Clip.none,
        children: [
          if (widget.shadow > 0) Transform.translate(offset: Offset(widget.shadow, widget.shadow), child: image(tint: Comic.ink)),
          image(),
        ],
      );
    } else if (_failed && widget.url != null) {
      child = CachedNetworkImage(
        key: const ValueKey('original'),
        imageUrl: widget.url!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined, color: Comic.ink),
      );
    } else if (_failed) {
      child = Icon(Icons.image_not_supported_outlined, key: const ValueKey('none'), color: Comic.ink, size: widget.size / 3);
    } else {
      child = const SizedBox.shrink(key: ValueKey('loading'));
    }
    return SizedBox(width: widget.size, height: widget.size, child: child);
  }
}
