import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final ScrollController _controller = ScrollController();

  bool loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    dio.options.headers["Demo-Header"] = "demo header"; // config your dio headers globally
    client = RestClient(dio);
    _loadItems();
    _initlisteners();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // use block pattern
    return Scaffold(
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.transparent,
      //   title: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Text(
      //           "DigiDex",
      //           style: TextStyle(color: Colors.grey[800], fontSize: 20),
      //         ),
      //       ),
      //       Visibility(
      //           child: SpinKitFadingCube(
      //         color: Colors.grey[800],
      //         size: 20.0,
      //       ))
      //     ],
      //   ),
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                      child: Text(
                        "DigiDex",
                        style: TextStyle(color: Colors.grey[800], fontSize: 20),
                      ),
                    ),
                    Visibility(
                        visible: loading,
                        child: SpinKitFadingCube(
                          color: Colors.grey[800],
                          size: 20.0,
                        ))
                  ],
                ),
                StackedListView(
                  controller: _controller,
                  key: _scaffoldKey,
                  padding: EdgeInsets.only(left: 20, right: 20, top: 20),
                  itemCount: digimon!.length,
                  itemExtent: 400,
                  heightFactor: 0.7,
                  fadeOutFrom: 0.7,
                  builder: (_, index) {
                    return digimon![index];
                  },
                ),
              ],
            ),
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
    loading = false;
    digimon = digimon?.toSet().toList();
  }

  Future<PaletteGenerator?> _localGen(String href) async {
    return paletteMap[href];
  }

  _updateList(endOfList) {
    if (endOfList) {
      page++;
      setState(() {
        print("Reloading List");
        _loadItems();
      });
    }
  }

  _initlisteners() {
    _controller.addListener(() {
      bool end = _controller.position.pixels > 0 && _controller.position.atEdge;
      _updateList(end);
    });
  }

  _loadItems() {
    setState(() {
      loading = true;
    });
    client.getPaginatedDigimon(page).then((values) {
      values.content?.forEach((element) {
        print("content $element");
        Digimon item = Digimon.$DigimonFromJson(element);
        client.getDigimon("${item.id}").then((details) => _getPaletteGenerator(details));
      });
    });
  }
}
