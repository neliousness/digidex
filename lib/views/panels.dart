import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../art/sticker_art.dart';
import '../data/digimon_repository.dart';
import '../models/digimon.dart';
import '../theme/comic_widgets.dart';
import 'nav.dart';

/// One diagonal comic panel. Neighbouring panels share a seam: each is
/// [height] tall but placed [_advance] apart, so they interlock with a thin
/// ink gap and no white.
class DigimonPanel extends StatelessWidget {
  static const double height = 186;
  static const double seam = 36;
  static const double gap = 6;
  static const double overlap = seam - gap;
  static const double _advance = height - overlap;
  static const List<Color> _colors = [
    Color(0xFF00B7FF), Color(0xFFFF3D7F), Color(0xFF7CF05A), Color(0xFFFF8A1F), //
    Color(0xFFA66BFF), Color(0xFFFFE14D), Color(0xFF00E0C6), Color(0xFFFF6FB5),
  ];

  final Digimon digimon;
  final int index;
  final String? levelHint;

  const DigimonPanel({super.key, required this.digimon, required this.index, this.levelHint});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final s = math.min(1.0, width / 390);
    final left = index.isEven;
    return SizedBox(
      height: _advance,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: height,
        maxHeight: height,
        child: Semantics(
          button: true,
          label: 'Open ${digimon.name}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => openDetail(context, digimon),
            child: ClipPath(
              clipper: _SeamClipper(evenIndex: left),
              child: Halftone(
                color: _colors[index % _colors.length],
                opacity: 0.18,
                child: Stack(
                  children: [
                    Positioned(
                      left: left ? 30 * s : null,
                      right: left ? null : 6 * s,
                      top: 22,
                      child: Transform.rotate(
                        angle: (left ? -6 : 6) * math.pi / 180,
                        child: StickerArt(url: digimon.image, size: 140, shadow: 5),
                      ),
                    ),
                    Positioned(
                      left: left ? 168 * s : 40 * s,
                      top: 62,
                      width: 180 * s,
                      child: Column(
                        crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          // Long names step down a size; long words shrink to fit whole.
                          OutlinedText(breakableName(digimon.name ?? ''),
                              size: fitLongestWord(digimon.name ?? '', maxSize: (digimon.name ?? '').length > 14 ? 21 : 28, width: 180 * s),
                              height: 1,
                              maxLines: 3,
                              textAlign: left ? TextAlign.left : TextAlign.right),
                          const SizedBox(height: 6),
                          _NoTag(digimon: digimon, levelHint: levelHint),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "#001 · CHILD". The list endpoint has no level, so it's fetched (and
/// cached) per row unless a level filter already says it.
class _NoTag extends StatelessWidget {
  final Digimon digimon;
  final String? levelHint;

  const _NoTag({required this.digimon, this.levelHint});

  @override
  Widget build(BuildContext context) {
    Widget tag(String? level) => ComicTag(level == null ? digimonNo(digimon.id) : '${digimonNo(digimon.id)} · $level', weight: 700);
    if (levelHint != null || digimon.id == null) return tag(levelHint);
    return FutureBuilder(
      future: context.read<DigimonRepository>().getDetails(digimon.id!),
      builder: (context, snapshot) {
        final level = snapshot.data?.primaryLevel;
        return tag(level == null || level == 'N/A' ? null : level);
      },
    );
  }
}

class _SeamClipper extends CustomClipper<Path> {
  final bool evenIndex;

  const _SeamClipper({required this.evenIndex});

  @override
  Path getClip(Size size) {
    const d = DigimonPanel.seam;
    final h = size.height;
    // Even panels slope down to the right at the top and up at the bottom; odd ones mirror.
    final topLeft = evenIndex ? 0.0 : d, topRight = evenIndex ? d : 0.0;
    final bottomLeft = evenIndex ? h : h - d, bottomRight = evenIndex ? h - d : h;
    return Path()
      ..moveTo(0, topLeft)
      ..lineTo(size.width, topRight)
      ..lineTo(size.width, bottomRight)
      ..lineTo(0, bottomLeft)
      ..close();
  }

  @override
  bool shouldReclip(_SeamClipper old) => old.evenIndex != evenIndex;
}
