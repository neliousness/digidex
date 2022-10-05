import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/constants.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:digidexplus/viewmodels/digimon_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'components/stacked_list.dart';
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _controller = ScrollController();

  Color bgColor = Colors.blue;
  double scale = 2.86;
  int page = 0;
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    // use block pattern
    return Consumer<DigimonViewModel>(builder: (context, model, child) {
      if (model.digimon.length == 1) {
        bgColor = ColorUtils.getColor(model.paletteGenerator, true);
      }

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
            stops: const [0.1, 1.0],
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
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                kAppName,
                                style: TextStyle(color: Colors.grey[800], fontSize: 26),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0, top: 8),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  "v$appVersion",
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 20,
                        child: Visibility(
                            visible: model.loading,
                            child: SpinKitFadingCube(
                              color: Colors.grey[800],
                              size: 20.0,
                            )),
                      )
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: StackedListView(
                      controller: _controller,
                      key: _scaffoldKey,
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                      itemCount: model.digimon.length,
                      itemExtent: 400,
                      heightFactor: 0.7,
                      fadeOutFrom: 0.7,
                      builder: (_, index) {
                        return model.digimon[index];
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
    _digimonViewModel.loadData(page);
  }

  _init() async {
    client = RestClient(dio);
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    _initListeners();
    _initObservers();
    _loadItems();
  }

  _initListeners() {
    _initScrollControllerListener();
  }

  _initScrollControllerListener() {
    _controller.addListener(() {
      int index = (_controller.position.pixels / (MediaQuery.of(context).size.height / scale)).ceil();
      index = index < 0 ? 0 : index;

      DigimonCard card = _digimonViewModel.digimon[index];

      setState(() {
        bgColor = ColorUtils.getColor(card.paletteGenerator!, true);
      });

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
  }

  @override
  void dispose() {
    super.dispose();
    _digimonViewModel.dispose();
  }
}
