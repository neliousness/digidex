import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/banner_ad_slot.dart';
import '../art/art_service.dart';
import '../art/sticker_art.dart';
import '../models/digimon.dart';
import '../models/digimon_details.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import '../utils/digimon_utils.dart';
import 'nav.dart';

/// Everything a Digimon evolves into, or from, as a grid of mini cards.
class EvolutionsView extends StatefulWidget {
  final DigimonDetails details;
  final bool into;

  const EvolutionsView({super.key, required this.details, this.into = true});

  @override
  State<EvolutionsView> createState() => _EvolutionsViewState();
}

class _EvolutionsViewState extends State<EvolutionsView> {
  static const List<double> _tilts = [-2, 1.5, -1, 2, -1.5, 1];

  late bool _into = widget.into;

  @override
  Widget build(BuildContext context) {
    final d = widget.details;
    final all = d.evolutions;
    final into = all.where((e) => e.isNext).toList();
    final from = all.where((e) => !e.isNext).toList();
    final list = _into ? into : from;
    final art = d.imageUrl == null ? null : context.read<ArtService>().cached(d.imageUrl!);
    final color = art?.colorFor(d.id!) ?? Comic.forId(d.id ?? 0);
    final name = d.name ?? '';

    Widget tab(String label, bool value) {
      final on = _into == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            onTap: () => setState(() => _into = value),
            child: ComicPanel(
              color: on ? Comic.ink : Comic.white,
              radius: 14,
              shadow: 4,
              shadowColor: on ? Comic.white : Comic.ink,
              child: SizedBox(
                height: 42,
                child: Center(child: Slant(child: Text(label.toUpperCase(), style: Comic.displayStyle(17, color: on ? Comic.yellow : Comic.ink)))),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Comic.light(color),
      bottomNavigationBar: const BannerAdSlot(),
      body: Halftone(
        color: Comic.light(color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ComicRoundButton(icon: Icons.arrow_back_rounded, label: 'Back to $name', onPressed: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 12),
                      StickerArt(url: d.imageUrl, size: 60, shadow: 3),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: OutlinedText(name, size: 30, maxLines: 1)),
                            const SizedBox(height: 4),
                            const ComicTag('Evolutions', rotation: -2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [tab('Into · ${into.length}', true), const SizedBox(width: 10), tab('From · ${from.length}', false)]),
                  const SizedBox(height: 14),
                  Text(
                    _into ? 'What $name can evolve into. Tap a card to open it.' : 'What can evolve into $name. Tap a card to open it.',
                    style: Comic.sansStyle(14, weight: 700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(_into ? 'Nothing evolves from here.' : 'No known earlier forms.', style: Comic.sansStyle(15, weight: 700)))
                  // Rows of three that size to their cards: a row without
                  // conditions isn't padded to the height of one with.
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.paddingOf(context).bottom),
                      itemCount: (list.length + 2) ~/ 3,
                      itemBuilder: (context, row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var c = 0; c < 3; c++) ...[
                              if (c > 0) const SizedBox(width: 12),
                              Expanded(
                                child: row * 3 + c < list.length
                                    ? _MiniCard(link: list[row * 3 + c], color: Comic.cycle(row * 3 + c), tilt: _tilts[(row * 3 + c) % _tilts.length])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final EvolutionLink link;
  final Color color;
  final double tilt;

  const _MiniCard({required this.link, required this.color, required this.tilt});

  @override
  Widget build(BuildContext context) {
    final name = DigimonUtils.formattedName(link.name);
    return Semantics(
      button: true,
      label: link.condition.isEmpty ? 'Open $name' : 'Open $name. ${link.condition}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openDetail(context, Digimon(id: link.id, name: name, image: link.imageUrl)),
        child: Transform.rotate(
          angle: tilt * math.pi / 180,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Comic.ink, width: 3),
                boxShadow: const [BoxShadow(color: Comic.ink, offset: Offset(4, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CustomPaint(
                  painter: const HalftonePainter(dotRadius: 1.3, spacing: 6, opacity: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StickerArt(url: link.imageUrl, size: 84, shadow: 3),
                        const SizedBox(height: 6),
                        ComicTag(name, color: Comic.white, fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3)),
                        if (link.condition.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: Comic.white, borderRadius: BorderRadius.circular(5), border: Border.all(color: Comic.ink, width: 2)),
                            child: Text(link.condition, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: Comic.sansStyle(10, weight: 700, height: 1.25)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
