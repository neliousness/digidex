import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/digimon.dart';
import '../models/digimon_details.dart';
import 'browse_view.dart';
import 'detail_view.dart';
import 'evolutions_view.dart';
import 'favorites_view.dart';

/// "1,488"
String formatCount(int n) {
  final s = '$n';
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// "#001"
String digimonNo(int? id) => '#${'${id ?? 0}'.padLeft(3, '0')}';

void openDetail(BuildContext context, Digimon digimon) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailView(digimon: digimon)));

void openEvolutions(BuildContext context, DigimonDetails details, {required bool into}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EvolutionsView(details: details, into: into)));

// The search field's keyboard must not outlive the page: back from search
// closes it whatever the field's focus was doing.
void openBrowse(BuildContext context, {bool focusSearch = false}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BrowseView(focusSearch: focusSearch))).whenComplete(hideKeyboard);

/// Drops text focus and closes the soft keyboard.
void hideKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

void openFavorites(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesView()));

Digimon summaryOf(DigimonDetails d) => Digimon(id: d.id, name: d.name, image: d.imageUrl);
