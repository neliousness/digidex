import 'package:digidexplus/main.dart';
import 'package:digidexplus/models/digimon_details.dart';
import 'package:digidexplus/sound/card_sounds.dart';
import 'package:digidexplus/viewmodels/home_viewmodel.dart';
import 'package:digidexplus/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_art_service.dart';
import 'support/fake_digimon_repository.dart';

/// Text in [OutlinedText] appears in several layers (fill, stroke, shadow),
/// so text finders look for "at least one".
Finder anyText(String text) => find.text(text.toUpperCase());

class RecordingSounds implements CardSounds {
  int ticks = 0;
  int draws = 0;

  @override
  void tick() => ticks++;

  @override
  void draw() => draws++;
}

Future<void> settle(WidgetTester tester) async {
  // Some motion keeps running (spinners while loading), so pump a few frames
  // rather than waiting to settle.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Loads the bundled fonts so text measures as it does on a phone (tests
/// otherwise use a block font).
Future<void> loadFonts() async {
  for (final family in {'BricolageGrotesque': 'fonts/BricolageGrotesque-Variable.ttf', 'DMSans': 'fonts/DMSans-Variable.ttf'}.entries) {
    await (FontLoader(family.key)..addFont(rootBundle.load(family.value))).load();
  }
}

const List<String> defaultNames = ['Agumon', 'Greymon', 'MetalGreymon', 'Gabumon', 'Garurumon', 'Patamon', 'Tailmon', 'Greymon (Blue)'];

Future<FakeDigimonRepository> pumpApp(WidgetTester tester, {List<String> names = defaultNames, CardSounds sounds = const SilentCardSounds(), Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  // The app turns its decorative motion off when the system asks; tests use that path.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = const Size(1080, 2220);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final catalogue = [for (var i = 0; i < names.length; i++) digimon(i + 1, names[i])];
  final repo = FakeDigimonRepository(
    catalogue: catalogue,
    pageSize: 4,
    details: {
      1: DigimonDetails(
        id: 1,
        name: 'Agumon',
        releaseDate: '1997',
        images: [{'href': 'https://example.com/1.png'}],
        levels: [{'id': 4, 'level': 'Child'}],
        attributes: [{'id': 4, 'attribute': 'Vaccine'}],
        types: [{'id': 1, 'type': 'Reptile'}],
        descriptions: [{'language': 'en_us', 'description': 'A reptile Digimon.'}, {'language': 'jap', 'description': '恐竜型デジモン。'}],
        skills: [for (var i = 1; i <= 5; i++) {'skill': 'Skill $i', 'description': 'Does thing $i.'}],
        fields: [{'field': 'Metal Empire'}],
        nextEvolutions: [{'id': 2, 'digimon': 'Greymon', 'condition': 'With or without Gabumon', 'image': 'https://example.com/2.png'}],
        priorEvolutions: [{'id': 9, 'digimon': 'Koromon', 'condition': '', 'image': 'https://example.com/9.png'}],
      ),
    },
  )..levels.addAll({1: 'Child', 4: 'Child', 2: 'Adult', 8: 'Adult', 3: 'Perfect'});
  await tester.pumpWidget(DigiDexApp(repository: repo, artService: FakeArtService(), sounds: sounds));
  await settle(tester);
  return repo;
}

Future<void> openSearch(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Search and browse all'));
  await settle(tester);
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  setUpAll(loadFonts);

  group('home', () {
    testWidgets('deals a hand; the header has favorites and search, nothing else', (tester) async {
      await pumpApp(tester);

      expect(anyText('Draw your partner!'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(r'^Favorites')), findsOneWidget);
      expect(find.bySemanticsLabel('Search and browse all'), findsOneWidget);
      expect(find.textContaining('BROWSE ALL'), findsNothing);
      expect(find.text('DigiDex'), findsOneWidget, reason: 'the wordmark, centred between the buttons');
      final favorites = tester.getCenter(find.bySemanticsLabel(RegExp(r'^Favorites')));
      final search = tester.getCenter(find.bySemanticsLabel('Search and browse all'));
      final wordmark = tester.getCenter(find.text('DigiDex'));
      expect(wordmark.dx, closeTo((favorites.dx + search.dx) / 2, 2));
      expect(find.bySemanticsLabel(RegExp(r'^Play ')).evaluate().length, greaterThanOrEqualTo(7));
    });

    testWidgets('tapping a card in the hand plays it as the big card, with a draw sound', (tester) async {
      final sounds = RecordingSounds();
      await pumpApp(tester, sounds: sounds);
      expect(sounds.draws, 0, reason: 'no sound for the opening deal');
      // The dial draws cards -4..4 left to right (the drawn one last); -2 is on screen.
      final card = find.bySemanticsLabel(RegExp(r'^Play ')).at(2);
      final name = tester.getSemantics(card).label.substring('Play '.length);

      await tester.tap(card);
      await settle(tester);

      expect(find.bySemanticsLabel('Open $name'), findsOneWidget);
      final model = Provider.of<HomeViewModel>(tester.element(find.byType(HomeView)), listen: false);
      expect(model.selectedSlot, -2);
      expect(sounds.draws, 1);
    });

    testWidgets('dragging the hand ticks once per card through the selected slot', (tester) async {
      final sounds = RecordingSounds();
      await pumpApp(tester, names: List.generate(40, (i) => 'Mon $i'), sounds: sounds);
      final model = Provider.of<HomeViewModel>(tester.element(find.byType(HomeView)), listen: false);
      expect(model.drawnIndex, 0);

      // About 69px of drag per card on a 360-wide phone; drag left by ~2 cards.
      await tester.drag(find.bySemanticsLabel(RegExp(r'^Your hand')), const Offset(-140, 0));
      await settle(tester);

      expect(model.drawnIndex, 2);
      expect(model.selectedSlot, 0);
      expect(find.bySemanticsLabel('Open ${model.drawnCard!.name}'), findsOneWidget, reason: 'the big card follows the dial');
      expect(sounds.ticks, 2);
      expect(sounds.draws, 1, reason: 'one draw sound when the dial settles');
    });
  });

  group('search', () {
    testWidgets('opens focused, shows everything, filters as you type', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);

      expect(tester.testTextInput.isVisible, isTrue, reason: 'the keyboard is up');
      expect(find.text('8'), findsOneWidget, reason: 'the total, unfiltered');
      expect(anyText('Agumon'), findsWidgets);

      await type(tester, 'grey');
      expect(find.text('3 MATCHES'), findsOneWidget);
      expect(anyText('Greymon'), findsWidgets);
      expect(anyText('Agumon'), findsNothing);
    });

    testWidgets('finds names the API filter misses, ignoring case and punctuation', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);

      await type(tester, 'BLUE');
      expect(find.text('1 MATCH'), findsOneWidget);
      await type(tester, '(blue)');
      expect(find.text('1 MATCH'), findsOneWidget);
      await type(tester, 'metal grey');
      expect(find.text('1 MATCH'), findsOneWidget);
      await type(tester, '  gabu  ');
      expect(find.text('1 MATCH'), findsOneWidget);
    });

    testWidgets('typing fast shows the last query; clearing shows everything', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);
      for (final q in ['g', 'ga', 'gab', 'gabu', 'gar', 'garu']) {
        await tester.enterText(find.byType(TextField), q);
      }
      await tester.pump();
      expect(find.text('1 MATCH'), findsOneWidget);
      expect(anyText('Garurumon'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(find.text('8'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('level chips combine with the search, with an empty state', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);

      await tester.tap(find.text('CHILD'));
      await settle(tester);
      expect(find.text('2 MATCHES'), findsOneWidget);

      await type(tester, 'grey');
      await settle(tester);
      expect(find.text('NO DIGIMON FOUND!'), findsOneWidget);

      await tester.drag(find.text('CHILD'), const Offset(-160, 0)); // swipe the chip row
      await tester.pump();
      await tester.tap(find.text('ADULT'));
      await settle(tester);
      expect(find.text('2 MATCHES'), findsOneWidget, reason: 'Greymon and Greymon (Blue)');

      await tester.drag(find.text('ADULT'), const Offset(300, 0)); // back to the start of the chip row
      await tester.pump();
      await tester.tap(find.text('ALL'));
      await settle(tester);
      expect(find.text('3 MATCHES'), findsOneWidget);
    });

    testWidgets('junk input shows the empty state, not an error', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);
      for (final junk in ['%', "'", 'zzz', '日本']) {
        await type(tester, junk);
        expect(find.text('NO DIGIMON FOUND!'), findsOneWidget, reason: junk);
      }
    });

    testWidgets('offline: a message and a working retry', (tester) async {
      final repo = await pumpApp(tester);
      repo.pageError = StateError('offline');
      await openSearch(tester);
      expect(find.text("Couldn't reach the Digimon database."), findsOneWidget);

      repo.pageError = null;
      await tester.tap(find.text('TRY AGAIN'));
      await settle(tester);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('the query is kept when you come back to search', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);
      await type(tester, 'gabu');
      await tester.tap(find.bySemanticsLabel('Back to home'));
      await settle(tester);

      await openSearch(tester);
      expect(find.text('gabu'), findsOneWidget);
      expect(find.text('1 MATCH'), findsOneWidget);
    });

    testWidgets('back from search closes the keyboard, and Home closes one that opens late', (tester) async {
      await pumpApp(tester);
      await openSearch(tester);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.binding.handlePopRoute(); // the system back
      await settle(tester);
      expect(find.byType(TextField), findsNothing, reason: 'back on Home');
      expect(tester.testTextInput.isVisible, isFalse);

      // A slow keyboard (Samsung's) shows up seconds later, over Home.
      tester.testTextInput.log.clear();
      tester.view.viewInsets = const FakeViewPadding(bottom: 800);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump();
      expect(tester.testTextInput.log.map((c) => c.method), contains('TextInput.hide'));
    });
  });

  group('favorites', () {
    testWidgets('empty at first; a hearted Digimon shows up, newest first', (tester) async {
      await pumpApp(tester, names: ['Agumon'], prefs: {'favorite_ids': ['5']});
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Favorites')));
      await settle(tester);
      expect(find.text('1 SAVED'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back to home'));
      await settle(tester);

      // Heart Agumon on its detail page.
      await tester.tap(find.bySemanticsLabel('Open Agumon'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Save Agumon'));
      await tester.pump();
      expect(find.bySemanticsLabel('Remove Agumon from saved'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await settle(tester);

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Favorites')));
      await settle(tester);
      expect(find.text('2 SAVED'), findsOneWidget);
      final panels = find.bySemanticsLabel(RegExp(r'^Open '));
      expect(tester.getSemantics(panels.first).label, 'Open Agumon', reason: 'newest first');
    });

    testWidgets('no favorites: a friendly empty state', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Favorites')));
      await settle(tester);
      expect(find.text('NO FAVORITES YET!'), findsOneWidget);
      expect(find.text('0 SAVED'), findsOneWidget);
    });
  });

  testWidgets('detail page end to end, with the evolutions screen', (tester) async {
    await pumpApp(tester, names: ['Agumon']);
    // A one-Digimon catalogue: the whole hand is Agumon (id 1), with full details.
    await tester.tap(find.bySemanticsLabel('Open Agumon'));
    await settle(tester);

    expect(find.text('A reptile Digimon.'), findsOneWidget);
    await tester.tap(find.text('日本語'));
    await tester.pump();
    expect(find.text('恐竜型デジモン。'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('SHOW ALL 5 SKILLS'), 300);
    expect(find.text('SKILL 3'), findsOneWidget);
    expect(find.text('SKILL 4'), findsNothing);
    await tester.tap(find.text('SHOW ALL 5 SKILLS'));
    await tester.pump();
    expect(find.text('SKILL 5'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('SEE ALL 2 EVOLUTIONS ›'), -300);
    await tester.tap(find.text('SEE ALL 2 EVOLUTIONS ›'));
    await settle(tester);
    expect(find.text('INTO · 1'), findsOneWidget);
    expect(find.text('With or without Gabumon'), findsOneWidget);

    await tester.tap(find.text('FROM · 1'));
    await tester.pump();
    expect(find.text('KOROMON'), findsOneWidget);
  });
}
