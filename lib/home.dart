import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'components/stacked_list.dart';

class Home extends StatefulWidget {
  static var id = '/home';

  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final dio = Dio(); // Provide a dio instance// config your dio headers globally
  late RestClient client;
  Map<String, PaletteGenerator> paletteMap = {};
  int page = 0;
  List<DigimonCard>? digimon = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    dio.options.headers["Demo-Header"] = "demo header"; // config your dio headers globally
    client = RestClient(dio);
    _loadItems();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  _loadItems() {
    client.getPaginatedDigimon(page).then((values) {
      values.content?.forEach((element) {
        print("content $element");
        Digimon item = Digimon.$DigimonFromJson(element);
        client.getDigimon("${item.id}").then((details) => _getPaletteGenerator(details));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // use block pattern
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "DigiDex",
          style: TextStyle(color: Colors.grey[800], fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: StackedListView(
            key: _scaffoldKey,
            padding: EdgeInsets.only(left: 20, right: 20, top: 50),
            itemCount: digimon!.length,
            itemExtent: 400,
            heightFactor: 0.7,
            fadeOutFrom: 0.7,
            builder: (_, index) {
              return digimon![index];
            },
          ),
        ),
      ),
    );
  }

  _getPaletteGenerator(DigimonDetails details) async {
    final image = details.images?[0]['href'];
    Future<PaletteGenerator?> gen = !paletteMap.containsKey(image) ? DigimonUtils.generatePalette(details) : _localGen(image);
    gen.then((palette) => _itemBuilder(details, palette!));
  }

  _itemBuilder(DigimonDetails details, PaletteGenerator generator) async {
    final image = details.images?[0]['href'];
    paletteMap[image] = generator;
    setState(() {
      digimon!.add(DigimonCard(
        client: client,
        paletteGenerator: generator,
        details: details,
        imageLink: image,
      ));
    });

    digimon = digimon?.toSet().toList();
  }

  Future<PaletteGenerator?> _localGen(String href) async {
    return paletteMap[href];
  }

  _updateList(int index, size) {
    print(index);
    print(size);
    bool endOfList = index >= size - 1;
    if (endOfList) {
      page++;
      setState(() {
        print("Reloading List");
      });
    }
  }
}
