import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_slot.dart';
import '../analytics/app_analytics.dart';
import '../art/art_service.dart';
import '../art/sticker_art.dart';
import '../data/digimon_repository.dart';
import '../data/favorites.dart';
import '../models/digimon.dart';
import '../models/digimon_details.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import '../utils/constants.dart';
import '../utils/digimon_utils.dart';
import '../viewmodels/digimon_single_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import 'nav.dart';
import 'rings.dart';

/// The six main evolution stages shown on the stage track.
const List<String> kStages = ['Baby I', 'Baby II', 'Child', 'Adult', 'Perfect', 'Ultimate'];

class DetailView extends StatefulWidget {
  /// The list item; its details are loaded here.
  final Digimon digimon;

  const DetailView({super.key, required this.digimon});

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> with TickerProviderStateMixin {
  late final DigimonSingleViewModel _model;
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 780));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 36));
  Color? _color;
  bool _japanese = false;
  bool _allSkills = false;

  @override
  void initState() {
    super.initState();
    _model = DigimonSingleViewModel(context.read<DigimonRepository>(), widget.digimon)
      ..addListener(_changed)
      ..load();
    context.read<AdService>().onDetailsOpened();
    if (widget.digimon.id != null) context.read<AppAnalytics>().digimonOpened(widget.digimon.id!, widget.digimon.name);
    final cached = widget.digimon.image == null ? null : context.read<ArtService>().cached(widget.digimon.image!);
    if (cached != null) _color = cached.colorFor(widget.digimon.id!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (comicMotion(context)) {
      if (!_spin.isAnimating) _spin.repeat();
      if (_intro.value == 0 && !_intro.isAnimating) _intro.forward();
    } else {
      _spin.stop();
      _intro.value = 1;
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _model.removeListener(_changed);
    _model.dispose();
    _intro.dispose();
    _spin.dispose();
    super.dispose();
  }

  Color get _themeColor => _color ?? Comic.forId(widget.digimon.id ?? 0);

  void _onArt(DigiArt art) {
    final color = art.colorFor(widget.digimon.id!);
    if (color == _color) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _color = color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = _model.details;
    final s = math.min(1.0, MediaQuery.sizeOf(context).width / 390);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Comic.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(digimon: widget.digimon, color: _themeColor, scale: s, intro: _intro, spin: _spin, onArt: _onArt),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Comic.ink, width: 5)),
              ),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 36 + bottom),
              child: details == null ? _loadingBody() : _body(details),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(0, -34),
          child: LayoutBuilder(
            builder: (context, c) => OutlinedText(
              breakableName(widget.digimon.name ?? ''),
              size: fitLongestWord(widget.digimon.name ?? '', maxSize: 60, width: c.maxWidth),
              stroke: 2,
              shadow: 4,
              height: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_model.failed) ...[
          Text("Couldn't load this Digimon.", style: Comic.sansStyle(17, weight: 500)),
          const SizedBox(height: 16),
          ComicButton('Try again', onPressed: _model.load, color: Comic.yellow),
        ] else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Comic.ink, strokeWidth: 4),
            ),
          ),
      ],
    );
  }

  Widget _body(DigimonDetails d) {
    final into = d.evolutions.where((e) => e.isNext).toList();
    final from = d.evolutions.where((e) => !e.isNext).toList();
    final skills = (d.skills ?? const []).whereType<Map>().toList();
    final fields = (d.fields ?? const []).whereType<Map>().map((f) => '${f['field'] ?? ''}').where((f) => f.isNotEmpty).toList();
    final english = DigimonUtils.getDescription(d.descriptions, 'en_us');
    final japanese = DigimonUtils.getDescription(d.descriptions, 'jap');
    const gap = SizedBox(height: 26);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The name overlaps the hero's bottom edge by 34px.
        Transform.translate(
          offset: const Offset(0, -34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) => OutlinedText(
                  breakableName(d.name ?? ''),
                  size: fitLongestWord(d.name ?? '', maxSize: 60, width: c.maxWidth),
                  stroke: 2,
                  shadow: 4,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 12),
              // Tags the API has no value for are left out.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (d.primaryLevel != kNA)
                    ComicTag(d.primaryLevel, color: Comic.white, rotation: -2, fontSize: 13, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                  if (d.primaryAttribute != kNA)
                    ComicTag(
                      d.primaryAttribute,
                      background: Comic.attributeColor(d.primaryAttribute),
                      color: Comic.ink,
                      rotation: 2,
                      bordered: true,
                      fontSize: 13,
                    ),
                  if (d.primaryType != kNA) ComicTag(d.primaryType, background: Comic.white, color: Comic.ink, rotation: -1, bordered: true, fontSize: 13),
                  if (d.releaseDate != null)
                    ComicTag('Debut ${d.releaseDate}', background: Comic.yellow, color: Comic.ink, rotation: 1, bordered: true, fontSize: 13),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26 - 34 + 8),
        _ProfileBubble(
          text: _japanese && japanese != 'N/A' ? japanese : english,
          japanese: _japanese,
          hasJapanese: japanese != 'N/A',
          onLanguage: (jp) => setState(() => _japanese = jp),
        ),
        gap,
        _StageTrack(level: d.primaryLevel, color: _themeColor),
        gap,
        _Numbers(skills: skills.length, into: into.length, from: from.length, xAntibody: d.xAntibody == true),
        if (fields.isNotEmpty) ...[gap, _Fields(fields: fields)],
        const BannerAdSlot(frame: BannerFrame.inline, gapAbove: 26),
        if (into.isNotEmpty || from.isNotEmpty) ...[
          gap,
          _EvolutionLine(
            current: d,
            color: _themeColor,
            prior: from.isEmpty ? null : from.first,
            next: into.take(2).toList(),
            total: into.length + from.length,
            onSeeAll: () {
              if (d.id != null) context.read<AppAnalytics>().evolutionsOpened(d.id!);
              openEvolutions(context, d, into: into.isNotEmpty);
            },
          ),
        ],
        if (skills.isNotEmpty) ...[gap, _Skills(skills: skills, showAll: _allSkills, color: _themeColor, onShowAll: () => setState(() => _allSkills = true))],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final Digimon digimon;
  final Color color;
  final double scale;
  final AnimationController intro;
  final AnimationController spin;
  final ValueChanged<DigiArt> onArt;

  const _Hero({required this.digimon, required this.color, required this.scale, required this.intro, required this.spin, required this.onArt});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final favorites = context.watch<Favorites>();
    final saved = digimon.id != null && favorites.contains(digimon.id!);
    final total = context.read<HomeViewModel>().total ?? HomeViewModel.fallbackTotal;
    final center = Offset(width / 2, top + 262 * s);

    return SizedBox(
      height: top + 470 * s,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: color),
        duration: const Duration(milliseconds: 350),
        builder: (context, c, _) {
          final ring = c ?? color;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: Halftone(color: Comic.light(ring), opacity: 0.17)),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([intro, spin]),
                  builder: (context, _) {
                    final t = intro.value * 0.78; // seconds; ring starts at 0.08s
                    return CustomPaint(
                      painter: RingsPainter(
                        style: RingsStyle.detail,
                        center: center,
                        scale: s,
                        color: ring,
                        outer: Ripple.at((t - 0.08) / 0.7),
                        spin: spin.value,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: (width - 270 * s) / 2,
                top: top + 122 * s,
                child: AnimatedBuilder(
                  animation: intro,
                  builder: (context, child) {
                    final r = Ripple.at((intro.value * 0.78 - 0.12) / 0.6);
                    return Opacity(
                      opacity: r.opacity,
                      child: Transform.scale(scale: r.scale, child: child),
                    );
                  },
                  child: StickerArt(url: digimon.image, size: 270 * s, shadow: 7 * s, onArt: onArt),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: top + 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ComicRoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                    ComicTag(
                      '${digimonNo(digimon.id)} / ${formatCount(total)}',
                      rotation: -3,
                      fontSize: 13,
                      weight: 700,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    ComicRoundButton(
                      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: saved ? 'Remove ${digimon.name} from saved' : 'Save ${digimon.name}',
                      color: saved ? Comic.swatches[2] : Comic.white,
                      iconColor: saved ? Comic.white : Comic.ink,
                      onPressed: digimon.id == null
                          ? null
                          : () {
                              favorites.toggle(digimon.id!);
                              context.read<AppAnalytics>().favoriteToggled(digimon.id!, added: !saved);
                            },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  final String text;
  final bool japanese;
  final bool hasJapanese;
  final ValueChanged<bool> onLanguage;

  const _ProfileBubble({required this.text, required this.japanese, required this.hasJapanese, required this.onLanguage});

  @override
  Widget build(BuildContext context) {
    Widget toggle(String label, bool jp) {
      final on = japanese == jp;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          onTap: () => onLanguage(jp),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? Comic.ink : Comic.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Comic.ink, width: 3),
            ),
            child: Text(label, style: Comic.sansStyle(12, weight: 800, color: on ? Comic.yellow : Comic.ink, letterSpacing: 0.6)),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ComicPanel(
          radius: 22,
          shadow: 6,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: Comic.sansStyle(17, height: 1.55)),
              if (hasJapanese) ...[
                const SizedBox(height: 12),
                Row(children: [toggle('ENGLISH', false), const SizedBox(width: 6), toggle('日本語', true)]),
              ],
            ],
          ),
        ),
        // The speech-bubble tail: a square with two ink sides, turned 45°.
        Positioned(
          left: 40,
          top: -11,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Comic.white,
                border: Border(
                  left: BorderSide(color: Comic.ink, width: 4),
                  top: BorderSide(color: Comic.ink, width: 4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageTrack extends StatelessWidget {
  final String level;
  final Color color;

  const _StageTrack({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final current = kStages.indexWhere((s) => s.toLowerCase() == level.toLowerCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTag('Stage'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < kStages.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: i == current ? color : (current >= 0 && i < current ? Comic.yellow : Comic.white),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Comic.ink, width: 3),
                    boxShadow: i == current ? const [BoxShadow(color: Comic.ink, offset: Offset(3, 3))] : null,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < kStages.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Text(
                  kStages[i].toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: Comic.sansStyle(10, weight: i == current ? 800 : 700, color: i == current ? Comic.ink : Comic.muted, letterSpacing: 0.2),
                ),
              ),
            ],
          ],
        ),
        if (current < 0 && level != 'N/A') ...[const SizedBox(height: 8), Text('Stage: ${level.toUpperCase()}', style: Comic.sansStyle(12, weight: 800))],
      ],
    );
  }
}

class _Numbers extends StatelessWidget {
  final int skills;
  final int into;
  final int from;
  final bool xAntibody;

  const _Numbers({required this.skills, required this.into, required this.from, required this.xAntibody});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, {Color color = Comic.white}) => ComicPanel(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Comic.sansStyle(12, weight: 800, color: Comic.muted, letterSpacing: 0.7)),
          Slant(child: Text(value, style: Comic.displayStyle(34))),
        ],
      ),
    );
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tile('SKILLS', '$skills')),
            const SizedBox(width: 12),
            Expanded(child: tile('EVOLVES INTO', '$into', color: Comic.yellow)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tile('EVOLVES FROM', '$from')),
            const SizedBox(width: 12),
            Expanded(child: tile('X-ANTIBODY', xAntibody ? 'YES' : 'NO')),
          ],
        ),
      ],
    );
  }
}

class _Fields extends StatelessWidget {
  final List<String> fields;

  const _Fields({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTag('Fields · ${fields.length}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in fields)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Comic.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Comic.ink, width: 3),
                ),
                child: Text(f, style: Comic.sansStyle(14, weight: 700)),
              ),
          ],
        ),
      ],
    );
  }
}

class _EvolutionLine extends StatelessWidget {
  final DigimonDetails current;
  final Color color;
  final EvolutionLink? prior;
  final List<EvolutionLink> next;
  final int total;
  final VoidCallback onSeeAll;

  const _EvolutionLine({required this.current, required this.color, required this.prior, required this.next, required this.total, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    Widget node(String name, String? image, Color background, {bool isCurrent = false, VoidCallback? onTap}) {
      final size = isCurrent ? 60.0 : 56.0;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: Border.all(color: Comic.ink, width: 3),
                  boxShadow: isCurrent ? const [BoxShadow(color: Comic.ink, offset: Offset(3, 3))] : null,
                ),
                child: ClipOval(
                  child: Center(
                    child: StickerArt(url: image, size: size - 8, shadow: 0),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Comic.sansStyle(10, weight: 800, height: 1.15),
              ),
            ],
          ),
        ),
      );
    }

    Widget arrow() => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text('›', style: Comic.displayStyle(20)),
    );
    void open(EvolutionLink e) => openDetail(context, Digimon(id: e.id, name: DigimonUtils.formattedName(e.name), image: e.imageUrl));

    final nodes = <Widget>[
      if (prior != null) node(prior!.name, prior!.imageUrl, Comic.cycle(7), onTap: () => open(prior!)),
      node(current.name ?? '', current.imageUrl, color, isCurrent: true),
      for (var i = 0; i < next.length; i++) node(next[i].name, next[i].imageUrl, Comic.cycle(i == 0 ? 1 : 4), onTap: () => open(next[i])),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTag('Evolution line'),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < nodes.length; i++) ...[if (i > 0) arrow(), nodes[i]],
          ],
        ),
        const SizedBox(height: 14),
        ComicButton('See all $total evolutions ›', color: Comic.yellow, onPressed: onSeeAll),
      ],
    );
  }
}

class _Skills extends StatelessWidget {
  static const int preview = 3;

  final List<Map> skills;
  final bool showAll;
  final Color color;
  final VoidCallback onShowAll;

  const _Skills({required this.skills, required this.showAll, required this.color, required this.onShowAll});

  @override
  Widget build(BuildContext context) {
    final shown = showAll ? skills : skills.take(preview).toList();
    final badge = [color, Comic.yellow, Comic.swatches[1]];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTag('Skills · ${skills.length}'),
        for (var i = 0; i < shown.length; i++) ...[
          const SizedBox(height: 12),
          ComicPanel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge[i % badge.length],
                    shape: BoxShape.circle,
                    border: Border.all(color: Comic.ink, width: 3),
                  ),
                  child: Text('${i + 1}'.padLeft(2, '0'), style: Comic.sansStyle(13, weight: 800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slant(child: Text('${shown[i]['skill'] ?? ''}'.toUpperCase(), style: Comic.displayStyle(19, height: 1.1))),
                      if ('${shown[i]['description'] ?? ''}'.isNotEmpty)
                        Text('${shown[i]['description']}', style: Comic.sansStyle(15, height: 1.45, color: Comic.body)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!showAll && skills.length > preview) ...[
          const SizedBox(height: 12),
          ComicButton('Show all ${skills.length} skills', height: 50, fontSize: 17, onPressed: onShowAll),
        ],
      ],
    );
  }
}
