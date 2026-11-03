import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/banner_ad_slot.dart';
import '../analytics/app_analytics.dart';
import '../art/sticker_art.dart';
import '../data/favorites.dart';
import '../sound/card_sounds.dart';
import '../models/digimon_details.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import '../viewmodels/home_viewmodel.dart';
import 'nav.dart';
import 'rings.dart';

/// "Draw your partner!": a hand of random Digimon; tapping one plays it as
/// the big card in front of the rings.
class HomeView extends StatefulWidget {
  static const String id = '/home';

  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Ripple (0.7s, outer ring 0.1s later) and the card's flight (0.55s).
  late final AnimationController _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _flight = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 36));
  late final AnimationController _spinBack = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  final Map<int, Color> _colors = {};
  int _playedDraws = -1;
  int? _playedCard;
  bool _motion = true;

  /// While the hand is being dragged the big card follows it without the
  /// draw animation, which plays once the hand settles.
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HomeViewModel>().deal());
  }

  // Nothing on Home types. Some keyboards (Samsung's) open seconds after
  // search asked for them, by when the user may be back here with a keyboard
  // nothing can close; close it as soon as it shows.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (View.of(context).viewInsets.bottom > 0) hideKeyboard();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = comicMotion(context);
    if (_motion) {
      if (!_spin.isAnimating) _spin.repeat();
      if (!_spinBack.isAnimating) _spinBack.repeat();
    } else {
      _spin.stop();
      _spinBack.stop();
      _ripple.value = 1;
      _flight.value = 1;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ripple.dispose();
    _flight.dispose();
    _spin.dispose();
    _spinBack.dispose();
    super.dispose();
  }

  Color _colorOf(DigimonDetails? d) => d?.id == null ? Comic.swatches[0] : _colors[d!.id!] ?? Comic.forId(d.id!);

  void _onArt(DigimonDetails d, Color color) {
    if (_colors[d.id!] == color) return;
    // Called from StickerArt while it builds; update after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _colors[d.id!] = color);
    });
  }

  /// Replays the ripple and the card's flight whenever a new card is played.
  void _maybePlay(HomeViewModel model) {
    final card = model.drawnCard;
    if (_dragging) {
      _flight.value = 1; // keep the swapping card fully visible
      return;
    }
    if (card == null || (model.draws == _playedDraws && card.id == _playedCard)) return;
    // Every draw after the opening deal lands with a sound. A tap counts a
    // new draw; otherwise the dial brought the card into the slot.
    if (_playedCard != null && card.id != null) {
      context.read<CardSounds>().draw();
      context.read<AppAnalytics>().cardDrawn(card.id!, fromDial: model.draws == _playedDraws);
    }
    _playedDraws = model.draws;
    _playedCard = card.id;
    if (_motion) {
      _ripple.forward(from: 0);
      _flight.forward(from: 0);
    } else {
      _ripple.value = 1;
      _flight.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();
    _maybePlay(model);
    final size = MediaQuery.sizeOf(context);
    final s = math.min(1.0, size.width / 390);
    final drawn = model.drawnCard;
    final ringColor = _colorOf(drawn);

    return Scaffold(
      backgroundColor: Comic.yellow,
      bottomNavigationBar: const BannerAdSlot(),
      body: Halftone(
        color: Comic.yellow,
        child: CustomMultiChildLayout(
          delegate: _HomeLayout(s),
          children: [
            LayoutId(
              id: _Part.rings,
              child: IgnorePointer(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: ringColor),
                  duration: const Duration(milliseconds: 350),
                  builder: (context, color, _) => AnimatedBuilder(
                    animation: Listenable.merge([_ripple, _spin, _spinBack]),
                    builder: (context, _) {
                      final t = _ripple.value * 0.8; // seconds into the 0.8s ripple
                      return CustomPaint(
                        painter: RingsPainter(
                          style: RingsStyle.home,
                          center: Offset(size.width / 2, _HomeLayout.ringsBox(s) / 2),
                          scale: s,
                          color: color ?? ringColor,
                          disc: Ripple.at(t / 0.7),
                          outer: Ripple.at((t - 0.1) / 0.7),
                          spin: _spin.value,
                          spinBack: _spinBack.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _Part.card,
              child: AnimatedBuilder(
                animation: _flight,
                builder: (context, child) => _CardFlight(t: _flight.value, scale: s, child: child!),
                child: drawn == null
                    ? _BigCard.placeholder(s)
                    : _BigCard(
                        key: ValueKey(drawn.id),
                        details: drawn,
                        color: ringColor,
                        scale: s,
                        onArt: (art) => _onArt(drawn, art.colorFor(drawn.id!)),
                        onTap: () => openDetail(context, summaryOf(drawn)),
                      ),
              ),
            ),
            LayoutId(id: _Part.header, child: const _Header()),
            LayoutId(
              id: _Part.hand,
              child: _Hand(
                model: model,
                scale: s,
                colorOf: _colorOf,
                onArt: _onArt,
                motion: _motion,
                onDragging: (dragging) => setState(() => _dragging = dragging),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Part { rings, card, header, hand }

/// Lays out header, stage (410 tall: the drawn card) and the hand below it.
/// Children paint in list order, so the rings sit behind the header and hand.
class _HomeLayout extends MultiChildLayoutDelegate {
  final double s;

  _HomeLayout(this.s);

  /// The rings' bounding box: the outer ring (r 262 + 14 stroke) both ways.
  static double ringsBox(double s) => 2 * (262 + 14) * s;

  @override
  void performLayout(Size size) {
    final header = layoutChild(_Part.header, BoxConstraints.loose(size));
    positionChild(_Part.header, Offset.zero);
    // Room between the header and the outer ring, so the pill doesn't touch it.
    final stageTop = header.height + 22 * s;

    // The rings' centre sits 205px below the stage top (the design's svg at -220, cy 425).
    final box = ringsBox(s);
    layoutChild(_Part.rings, BoxConstraints.tight(Size(size.width, box)));
    positionChild(_Part.rings, Offset(0, stageTop + 205 * s - box / 2));

    final card = Size(266 * s, 366 * s);
    layoutChild(_Part.card, BoxConstraints.tight(card));
    positionChild(_Part.card, Offset((size.width - card.width) / 2, stageTop + 22 * s));

    final handTop = stageTop + 410 * s;
    layoutChild(_Part.hand, BoxConstraints.tight(Size(size.width, math.max(0, size.height - handTop))));
    positionChild(_Part.hand, Offset(0, handTop));
  }

  @override
  bool shouldRelayout(_HomeLayout old) => old.s != s;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<Favorites>().ids.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ComicRoundButton(
                icon: Icons.favorite_rounded,
                label: saved == 0 ? 'Favorites' : 'Favorites, $saved saved',
                size: 44,
                color: Comic.swatches[2],
                iconColor: Comic.white,
                onPressed: () => openFavorites(context),
              ),
              // The wordmark sits centred between the two buttons, as in the original app.
              Expanded(
                child: Center(
                  child: Slant(child: Text('DigiDex', style: Comic.displayStyle(24))),
                ),
              ),
              ComicRoundButton(icon: Icons.search_rounded, label: 'Search and browse all', size: 44, onPressed: () => openBrowse(context, focusSearch: true)),
            ],
          ),
          const SizedBox(height: 8),
          const OutlinedText('Draw your partner!', size: 34),
        ],
      ),
    );
  }
}

/// The drawn card's flight: from below, tilted and small, overshooting into
/// place at −3°. Easing applies per keyframe segment, as in the CSS.
class _CardFlight extends StatelessWidget {
  static const Cubic _ease = Cubic(0.2, 0.9, 0.25, 1.15);

  final double t;
  final double scale;
  final Widget child;

  const _CardFlight({required this.t, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    double y, rot, sc, opacity;
    if (t < 0.6) {
      final e = _ease.transform(t / 0.6);
      y = 120 + (-8 - 120) * e;
      rot = -16 + 18 * e;
      sc = 0.6 + 0.45 * e;
      opacity = e.clamp(0.0, 1.0);
    } else {
      final e = _ease.transform((t - 0.6) / 0.4);
      y = -8 + 8 * e;
      rot = 2 - 5 * e;
      sc = 1.05 - 0.05 * e;
      opacity = 1;
    }
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, y * scale, 0)
          ..rotateZ(rot * math.pi / 180)
          ..scaleByDouble(sc, sc, 1, 1),
        child: child,
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final DigimonDetails? details;
  final Color color;
  final double scale;
  final VoidCallback? onTap;
  final ValueChanged<dynamic>? onArt;

  const _BigCard({super.key, required this.details, required this.color, required this.scale, this.onTap, this.onArt});

  static Widget placeholder(double s) => _BigCard(details: null, color: Comic.white, scale: s);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = details;
    return Semantics(
      button: d != null,
      label: d == null ? 'Dealing cards' : 'Open ${d.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(color: Comic.ink, width: 5 * s),
            boxShadow: [BoxShadow(color: Comic.ink, offset: Offset(8 * s, 8 * s))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17 * s),
            child: CustomPaint(
              painter: HalftonePainter(dotRadius: 1.6 * s, spacing: 8 * s, opacity: 0.2),
              child: d == null
                  ? Center(
                      child: Slant(child: Text('DEALING…', style: Comic.displayStyle(26 * s))),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 14 * s),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ComicTag(digimonNo(d.id), fontSize: 12 * s, weight: 700),
                              if (d.primaryAttribute != 'N/A')
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
                                  decoration: BoxDecoration(
                                    color: Comic.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Comic.ink, width: 2),
                                  ),
                                  child: Text(d.primaryAttribute.toUpperCase(), style: Comic.sansStyle(12 * s, weight: 800, letterSpacing: 0.5)),
                                ),
                            ],
                          ),
                          SizedBox(height: 2 * s),
                          StickerArt(url: d.imageUrl, size: 206 * s, shadow: 5 * s, onArt: onArt),
                          SizedBox(height: 14 * s),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: OutlinedText(d.name ?? '', size: 36 * s, maxLines: 1, height: 1),
                          ),
                          SizedBox(height: 10 * s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (d.primaryLevel != 'N/A')
                                Flexible(
                                  child: ComicTag(
                                    d.primaryLevel,
                                    color: Comic.white,
                                    fontSize: 12 * s,
                                    weight: 700,
                                    padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                                  ),
                                ),
                              if (d.primaryLevel != 'N/A' && d.primaryType != 'N/A') SizedBox(width: 6 * s),
                              if (d.primaryType != 'N/A')
                                Flexible(
                                  child: ComicTag(
                                    d.primaryType,
                                    color: Comic.white,
                                    fontSize: 12 * s,
                                    weight: 700,
                                    padding: EdgeInsets.symmetric(horizontal: 9 * s, vertical: 4 * s),
                                  ),
                                ),
                            ],
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

/// The hand as an endless dial: drag sideways to fan new cards in from the
/// sides. The selected slot stays put, so each card passing through it
/// becomes the drawn card.
class _Hand extends StatefulWidget {
  final HomeViewModel model;
  final double scale;
  final Color Function(DigimonDetails?) colorOf;
  final void Function(DigimonDetails, Color) onArt;
  final bool motion;
  final ValueChanged<bool> onDragging;

  const _Hand({required this.model, required this.scale, required this.colorOf, required this.onArt, required this.motion, required this.onDragging});

  @override
  State<_Hand> createState() => _HandState();
}

class _HandState extends State<_Hand> with SingleTickerProviderStateMixin {
  static const double _degreesPerCard = 9;
  static const double _visible = 4.6; // cards either side of the centre that are drawn

  /// Which deck position is in the middle of the fan; fractional while moving.
  double _scroll = 0;
  late final AnimationController _settle = AnimationController.unbounded(vsync: this)..addListener(_onSettleTick);
  bool _active = false;

  /// Drag distance that moves the fan by one card: the arc between two cards
  /// at the card tops, 440px from the pivot.
  double get _pixelsPerCard => 440 * widget.scale * _degreesPerCard * math.pi / 180;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _setScroll(double value) {
    // A tick for every card that moves into the slot (a quick flick can pass
    // several in one frame; the sounds space them out).
    final passed = (value.round() - _scroll.round()).abs();
    if (passed > 0) {
      final sounds = context.read<CardSounds>();
      for (var i = 0; i < passed.clamp(0, 4); i++) {
        sounds.tick();
      }
    }
    setState(() => _scroll = value);
    widget.model.scrollTo(value.round());
  }

  void _onSettleTick() => _setScroll(_settle.value);

  void _start() {
    _settle.stop();
    if (!_active) {
      _active = true;
      widget.onDragging(true);
    }
  }

  void _finish() {
    if (_active) {
      _active = false;
      widget.onDragging(false);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    // A fling carries on for a few cards, then snaps to the nearest one.
    final cardsPerSecond = -(details.primaryVelocity ?? 0) / _pixelsPerCard;
    final target = (_scroll + cardsPerSecond * 0.22).roundToDouble();
    _snapTo(target);
  }

  void _snapTo(double target) {
    if (!widget.motion || (target - _scroll).abs() < 0.001) {
      _setScroll(target);
      _finish();
      return;
    }
    _settle.value = _scroll;
    final ms = (200 + 90 * (target - _scroll).abs()).clamp(200, 700).round();
    _settle
        .animateTo(
          target,
          duration: Duration(milliseconds: ms),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(_finish);
  }

  void _step(int cards) {
    _start();
    _snapTo(_scroll.roundToDouble() + cards);
  }

  void _play(int index) {
    final center = _scroll.roundToDouble();
    _setScroll(center);
    widget.model.select(index, slot: index - center.round());
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final model = widget.model;
    final drawn = model.drawnIndex;
    final first = (_scroll - _visible).ceil(), last = (_scroll + _visible).floor();
    // Left to right, with the drawn card on top.
    final order = [
      for (var k = first; k <= last; k++)
        if (k != drawn) k,
      if (drawn >= first && drawn <= last) drawn,
    ];

    return Semantics(
      label: 'Your hand. Drag sideways for more cards.',
      onScrollLeft: () => _step(1),
      onScrollRight: () => _step(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => _start(),
        onHorizontalDragUpdate: (d) => _setScroll(_scroll - d.delta.dx / _pixelsPerCard),
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: () => _snapTo(_scroll.roundToDouble()),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (final k in order)
                Positioned(
                  key: ValueKey('hand-$k'),
                  left: constraints.maxWidth / 2 - 40 * s,
                  top: 40 * s,
                  width: 80 * s,
                  height: 112 * s,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: k == drawn ? -34 : 0),
                    duration: widget.motion ? const Duration(milliseconds: 350) : Duration.zero,
                    curve: const Cubic(0.2, 0.9, 0.25, 1.2),
                    builder: (context, lift, child) => Transform(
                      origin: Offset(40 * s, 440 * s),
                      transform: Matrix4.rotationZ((k - _scroll) * _degreesPerCard * math.pi / 180)..translateByDouble(0, lift * s, 0, 1),
                      child: child,
                    ),
                    child: _HandCard(
                      details: model.cardAt(k),
                      on: k == drawn,
                      color: widget.colorOf(model.cardAt(k)),
                      scale: s,
                      onArt: widget.onArt,
                      onTap: () => _play(k),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandCard extends StatelessWidget {
  final DigimonDetails? details;
  final bool on;
  final Color color;
  final double scale;
  final void Function(DigimonDetails, Color) onArt;
  final VoidCallback onTap;

  const _HandCard({required this.details, required this.on, required this.color, required this.scale, required this.onArt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = details;
    return Semantics(
      button: true,
      selected: on,
      label: d == null ? 'Card loading' : 'Play ${d.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12 * s),
            border: Border.all(color: Comic.ink, width: 3 * s),
            boxShadow: on
                ? [BoxShadow(color: Comic.white, spreadRadius: 3 * s), BoxShadow(color: Comic.ink, offset: Offset(6 * s, 6 * s))]
                : [BoxShadow(color: Comic.ink, offset: Offset(3 * s, 3 * s))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9 * s),
            child: CustomPaint(
              painter: HalftonePainter(dotRadius: 1.3 * s, spacing: 6 * s, opacity: 0.2),
              child: d == null
                  ? const SizedBox.expand()
                  : Padding(
                      padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 4 * s),
                      child: Column(
                        children: [
                          StickerArt(url: d.imageUrl, size: 64 * s, shadow: 2 * s, onArt: (art) => onArt(d, art.colorFor(d.id!))),
                          SizedBox(height: 4 * s),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ComicTag(
                              d.name ?? '',
                              color: Comic.white,
                              fontSize: 9 * s,
                              padding: EdgeInsets.symmetric(horizontal: 4 * s, vertical: 2 * s),
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
