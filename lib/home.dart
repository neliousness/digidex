import 'dart:async';

import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/constants.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:digidexplus/viewmodels/digimon_single_viewmodel.dart';
import 'package:digidexplus/viewmodels/digimon_viewmodel.dart';
import 'package:digidexplus/views/digimon_details_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final dio = Dio();
  late RestClient client;
  late DigimonViewModel _digimonViewModel;
  late DigimonSingleViewModel _digimonSingleViewModel;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _controller = ScrollController();

  Color bgColor = Colors.blue;
  double scale = 2.86;
  int page = 0;
  String appVersion = "";
  bool searchFocused = false;
  bool searching = false;
  bool notFound = false;
  late FocusNode _focusNode;

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
          child: Stack(children: [
            SingleChildScrollView(
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
            Visibility(
              visible: searchFocused,
              child: AnimatedContainer(
                curve: Curves.easeInOut,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black54.withOpacity(0.5),
                duration: Duration(milliseconds: 1000),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  searchFocused = !searchFocused;
                  Timer.periodic(Duration(milliseconds: 1000), (timer) {
                    _focusNode.requestFocus();
                    timer.cancel();
                  });
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0, bottom: 20),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.fastOutSlowIn,
                  alignment: searchFocused ? const Alignment(1.0, -0.82) : Alignment.bottomRight,
                  child: AnimatedContainer(
                    height: searchFocused ? 55 : 65,
                    width: searchFocused ? MediaQuery.of(context).size.width - 50 : 65,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(searchFocused ? 8 : 200),
                        color: ColorUtils.darken(bgColor, 15),
                        shape: BoxShape.rectangle,
                        boxShadow: [BoxShadow(color: Colors.black54.withOpacity(0.15), spreadRadius: 2, blurRadius: 5, offset: const Offset(1, 2.7))]),
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _getTranslatedWidget(),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _getTranslatedWidget() {
    if (!searchFocused) {
      return const Icon(
        Icons.search,
        color: Colors.white,
      );
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 5,
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 7,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    child: TextField(
                      onSubmitted: (value) {
                        _findDigimon(value);
                        _focusNode.requestFocus();
                      },
                      textInputAction: TextInputAction.search,
                      focusNode: _focusNode,
                      cursorColor: ColorUtils.darken(bgColor, 5),
                      style: const TextStyle(fontSize: 20, height: 1.25, color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(top: 0, left: 10),
                        hintText: "Search..",
                        hintStyle: TextStyle(color: Colors.transparent.withOpacity(0.35)),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          notFound = false;
                        });
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _focusNode.unfocus();
                    setState(() {
                      searchFocused = !searchFocused;
                      notFound = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: searching
                        ? const SpinKitFadingCube(
                            color: Colors.white,
                            size: 15.0,
                          )
                        : const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                  ),
                )
              ],
            ),
            Visibility(
              visible: notFound,
              child: const Align(
                alignment: Alignment(0, 4),
                child: Text(
                  "Sorry, that digimon doesn't exist",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      );
    }
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
    _focusNode = FocusNode();
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
    _initSingleDigimonObserver();
  }

  _initDigimonViewModelObserver() {
    _digimonViewModel = Provider.of<DigimonViewModel>(context, listen: false);
    _digimonSingleViewModel = Provider.of<DigimonSingleViewModel>(context, listen: false);
    _digimonViewModel.init(client);
    _digimonSingleViewModel.init(client);
  }

  _initSingleDigimonObserver() {
    _digimonSingleViewModel.addListener(() {
      if (_digimonSingleViewModel.value is DigiData) {
        DigiData data = _digimonSingleViewModel.value;
        if (data.search && data.details != null && data.generator != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DigimonDetailsView(
                        paletteGenerator: data.generator,
                        imageLink: data.details?.images?[0][kHref],
                        details: data.details,
                        client: client,
                      )));
        } else {
          setState(() {
            notFound = true;
          });
          print("digimon not found");
        }
        setState(() {
          searching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _digimonViewModel.dispose();
    _digimonSingleViewModel.dispose();
  }

  void _findDigimon(String name) {
    setState(() {
      searching = true;
    });
    _digimonSingleViewModel.getSingleDigimonByName(name.trimRight().trimLeft());
  }
}
