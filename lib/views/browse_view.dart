import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/banner_ad_slot.dart';
import '../theme/comic.dart';
import '../theme/comic_widgets.dart';
import '../viewmodels/browse_viewmodel.dart';
import 'detail_view.dart';
import 'nav.dart';
import 'panels.dart';

/// Browse every Digimon, search by partial name and filter by level.
class BrowseView extends StatefulWidget {
  final bool focusSearch;

  const BrowseView({super.key, this.focusSearch = false});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  static const List<String> _levels = [...kStages, 'Armor', 'Hybrid'];

  late final BrowseViewModel _model = context.read<BrowseViewModel>();
  late final TextEditingController _search = TextEditingController(text: _model.query);
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // left before the first frame
      _model.load();
      if (widget.focusSearch && (ModalRoute.of(context)?.isCurrent ?? false)) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    if (_searchFocus.hasFocus) hideKeyboard();
    _scroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // Search runs on the device, so results follow every keystroke.
  void _onQuery(String text) {
    _toTop();
    _model.setQuery(text);
    setState(() {}); // the clear button
  }

  void _setLevel(String? level) {
    _toTop();
    _model.setLevel(level);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BrowseViewModel>();
    final count = model.filtered ? model.results.length : model.total;
    final countLabel = count == null || model.loading
        ? '…'
        : model.filtered
            ? '${formatCount(count)} ${count == 1 ? 'MATCH' : 'MATCHES'}'
            : formatCount(count);
    final digimon = model.results;

    Widget body;
    if (model.failed) {
      body = _failed();
    } else if (model.noResults) {
      body = _empty();
    } else if (model.loading && digimon.isEmpty) {
      body = const Center(child: CircularProgressIndicator(color: Comic.yellow, strokeWidth: 4));
    } else {
      body = ListView.builder(
        controller: _scroll,
        // Scrolling the results puts the keyboard away.
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: DigimonPanel.overlap + 12),
        itemCount: digimon.length,
        itemBuilder: (context, k) => DigimonPanel(key: ValueKey(digimon[k].id), digimon: digimon[k], index: k, levelHint: model.level),
      );
    }

    return Scaffold(
      backgroundColor: Comic.ink,
      bottomNavigationBar: const BannerAdSlot(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(countLabel, model.level),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _header(String countLabel, String? level) {
    Widget chip(String label, bool on, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            button: true,
            selected: on,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Comic.ink : Comic.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Comic.ink, width: 3),
                  boxShadow: on ? null : const [BoxShadow(color: Comic.ink, offset: Offset(2, 2))],
                ),
                child: Text(label.toUpperCase(), style: Comic.sansStyle(13, weight: 800, color: on ? Comic.yellow : Comic.ink, letterSpacing: 0.6)),
              ),
            ),
          ),
        );

    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Comic.ink, width: 5))),
      child: Halftone(
        color: Comic.yellow,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    ComicRoundButton(icon: Icons.arrow_back_rounded, label: 'Back to home', onPressed: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 12),
                    // The design is 390 wide; on narrower phones the title gives way.
                    const Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: OutlinedText('Browse all', size: 32, height: 1))),
                    const SizedBox(width: 8),
                    ComicTag(countLabel, rotation: 3),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ComicPanel(
                  radius: 14,
                  shadow: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: Comic.ink, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            focusNode: _searchFocus,
                            onChanged: _onQuery,
                            onSubmitted: (_) => _searchFocus.unfocus(),
                            textInputAction: TextInputAction.search,
                            cursorColor: Comic.ink,
                            style: Comic.sansStyle(17, weight: 700),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: 'Search a name, e.g. grey',
                              hintStyle: Comic.sansStyle(17, weight: 700, color: const Color(0xFF55555F)),
                            ),
                          ),
                        ),
                        if (_search.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _search.clear();
                              _onQuery('');
                            },
                            child: const Icon(Icons.close_rounded, color: Comic.ink),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20, bottom: 4, top: 2),
                  children: [
                    chip('All', level == null, () => _setLevel(null)),
                    for (final l in _levels) chip(l, level == l, () => _setLevel(l)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ComicPanel(
          radius: 22,
          shadow: 6,
          shadowColor: Comic.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slant(child: Text('NO DIGIMON FOUND!', textAlign: TextAlign.center, style: Comic.displayStyle(28))),
              const SizedBox(height: 6),
              Text('Try fewer letters, or another level.', textAlign: TextAlign.center, style: Comic.sansStyle(15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _failed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't reach the Digimon database.", textAlign: TextAlign.center, style: Comic.sansStyle(16, weight: 700, color: Comic.white)),
            const SizedBox(height: 16),
            ComicButton('Try again', color: Comic.yellow, onPressed: _model.retry),
          ],
        ),
      ),
    );
  }
}
