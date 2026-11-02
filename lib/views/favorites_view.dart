import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/banner_ad_slot.dart';
import '../data/digimon_repository.dart';
import '../data/favorites.dart';
import '../models/digimon.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import 'nav.dart';
import 'panels.dart';

/// The Digimon saved with the heart, most recent first.
class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  // Names and art come from the full list, which Browse shares and caches.
  late Future<List<Digimon>> _all = context.read<DigimonRepository>().getAll();

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<Favorites>().ids;
    return Scaffold(
      backgroundColor: Comic.ink,
      bottomNavigationBar: const BannerAdSlot(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(ids.length),
          Expanded(
            child: ids.isEmpty
                ? _message('No favorites yet!', 'Tap the heart on any Digimon to keep it here.')
                : FutureBuilder<List<Digimon>>(
                    future: _all,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _message("Couldn't load your favorites", 'Check your connection and try again.',
                            onRetry: () => setState(() => _all = context.read<DigimonRepository>().getAll()));
                      }
                      final all = snapshot.data;
                      if (all == null) return const Center(child: CircularProgressIndicator(color: Comic.yellow, strokeWidth: 4));
                      final byId = {for (final d in all) d.id: d};
                      // A saved id the list doesn't know still opens, by number.
                      final saved = [for (final id in ids) byId[id] ?? Digimon(id: id, name: digimonNo(id))];
                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: DigimonPanel.overlap + 12),
                        itemCount: saved.length,
                        itemBuilder: (context, k) => DigimonPanel(key: ValueKey(saved[k].id), digimon: saved[k], index: k),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(int count) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Comic.ink, width: 5))),
      child: Halftone(
        color: Comic.swatches[7],
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 16),
          child: Row(
            children: [
              ComicRoundButton(icon: Icons.arrow_back_rounded, label: 'Back to home', onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 12),
              const Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: OutlinedText('Favorites', size: 32, height: 1))),
              const SizedBox(width: 8),
              ComicTag(count == 1 ? '1 SAVED' : '${formatCount(count)} SAVED', rotation: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String title, String body, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ComicPanel(
          radius: 22,
          shadow: 6,
          shadowColor: Comic.swatches[7],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slant(child: Text(title.toUpperCase(), textAlign: TextAlign.center, style: Comic.displayStyle(28))),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: Comic.sansStyle(15)),
              if (onRetry != null) ...[const SizedBox(height: 16), ComicButton('Try again', color: Comic.yellow, onPressed: onRetry)],
            ],
          ),
        ),
      ),
    );
  }
}
