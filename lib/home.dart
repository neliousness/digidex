import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:digidexplus/viewmodels/digimon_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

import 'components/stacked_list.dart';
import 'models/digimon.dart';
import 'models/digimon_details.dart';
import 'utils/color_utils.dart';

class Home extends StatefulWidget {
  static var id = '/home';

  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final dio = Dio();
  late RestClient client;
  late DigimonViewModel _digimonViewModel;
  late dynamic _digimonListener;

  int page = 0;
  List<DigimonCard>? digimon = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _controller = ScrollController();

  bool loading = false;
  Color bgColor = Colors.blue;
  double scale = 2.86;

  @override
  void initState() {
    super.initState();

    client = RestClient(dio);

    _initListeners();
    _initObservers();
    _loadItems();
  }

  // @override
  // void setState(fn) {
  //   if (mounted) super.setState(fn);
  // }

  @override
  Widget build(BuildContext context) {
    // use block pattern
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            ColorUtils.darken(bgColor.withOpacity(0.7)),
            bgColor.withOpacity(0.005),
          ],
          begin: const FractionalOffset(1.0, 1.0),
          end: const FractionalOffset(1.0, 0.1),
          stops: [0.1, 1.0],
        )),
        child: SingleChildScrollView(
          child: SafeArea(
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
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: StackedListView(
                    controller: _controller,
                    key: _scaffoldKey,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    itemCount: digimon!.length,
                    itemExtent: 400,
                    heightFactor: 0.7,
                    fadeOutFrom: 0.7,
                    builder: (_, index) {
                      return digimon![index];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _cardBuilder(DigiData data) async {
    DigimonDetails details = data.details;
    PaletteGenerator generator = data.generator;

    final image = details.images?[0]['href'];
    _digimonViewModel.paletteMap[image] = generator;
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

  _updateList(endOfList) {
    if (endOfList) {
      page++;
      setState(() {
        print("Reloading List");
        _loadItems();
      });
    }
  }

  _loadItems() {
    setState(() {
      loading = true;
    });
    _digimonViewModel.loadData(page);
  }

  _initListeners() {
    _initScrollControllerListener();
    _initDigimonViewModelListener();
  }

  _initDigimonViewModelListener() {
    _digimonListener = () {
      _cardBuilder(_digimonViewModel.value as DigiData);
    };
  }

  _initScrollControllerListener() {
    _controller.addListener(() {
      int index = (_controller.position.pixels / (MediaQuery.of(context).size.height / scale)).ceil();
      index = index < 0 ? 0 : index;
      print(MediaQuery.of(context).size.height / scale);

      DigimonCard card = digimon![index];

      setState(() {
        bgColor = ColorUtils.getColor(card.paletteGenerator!, true);
      });

      print(" index $index");
      bool end = _controller.position.pixels > 0 && _controller.position.atEdge;
      _updateList(end);
    });
  }

  _initObservers() {
    _initDigimonViewModelObserver();
  }

  _initDigimonViewModelObserver() {
    _digimonViewModel = Provider.of<DigimonViewModel>(context, listen: false);
    _digimonViewModel.init(client);
    _digimonViewModel.addListener(_digimonListener);
  }

  @override
  void dispose() {
    super.dispose();
    _digimonViewModel.dispose();
    _digimonListener.dispose();
  }
}
