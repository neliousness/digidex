import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../utils/retro-client.dart';

class DigimonDetailsView extends StatefulWidget {
  final PaletteGenerator? paletteGenerator;
  final DigimonDetails? details;
  final String imageLink;
  const DigimonDetailsView({Key? key, required this.paletteGenerator, required this.details, required this.imageLink}) : super(key: key);

  @override
  _DigimonDetailsViewState createState() => _DigimonDetailsViewState();
}

class _DigimonDetailsViewState extends State<DigimonDetailsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(),
    );
  }
}
