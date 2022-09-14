import 'package:digidexplus/components/digimon_card.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:stacked_listview/stacked_listview.dart';

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    dio.options.headers["Demo-Header"] = "demo header"; // config your dio headers globally
    client = RestClient(dio);
    _loadItems();
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
      body: Center(
        child: StackedListView(
          padding: EdgeInsets.only(left: 20, right: 20, top: 50),
          itemCount: digimon!.length,
          itemExtent: 400,
          heightFactor: 0.7,
          fadeOutFrom: 0.7,
          onRemove: (index) {
            _updateList(index, digimon!.length);
            setState(() {
              digimon!.removeAt(index);
            });
          },
          builder: (_, index) {
            return digimon![index];
          },
        ),
      ),
    );
  }

  // Widget cardView(Digimon? item) {
  //   if (item != null && item.id! > -1) {
  //     return Center(
  //       child: FutureBuilder<DigimonDetails>(
  //           future: client.getDigimon("${item.id}"),
  //           builder: (context, AsyncSnapshot<DigimonDetails> snapshot) {
  //             if (snapshot.hasError) {
  //               return const CircularProgressIndicator();
  //             } else {
  //               print(snapshot.data);
  //               final image = snapshot.data?.images?[0]['href'];
  //               return FutureBuilder<PaletteGenerator?>(
  //                   future: !paletteMap.containsKey(image) ? DigimonUtils.generatePalette(snapshot.data) : _localGen(image),
  //                   builder: (context, AsyncSnapshot<PaletteGenerator?> snapshot2) {
  //                     if (snapshot2.hasError) {
  //                       return CircularProgressIndicator();
  //                     } else if (snapshot2.hasData) {
  //                       paletteMap[image] = snapshot2.data!;
  //                       return GestureDetector(
  //                         onTap: () {
  //                           Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                   builder: (context) =>
  //                                       DigimonDetailsView(
  //                                         paletteGenerator: snapshot2.data,
  //                                         imageLink: image,
  //                                         details: snapshot.data,
  //                                         client: client,
  //                                       )));
  //                         },
  //                         child: Padding(
  //                           padding: const EdgeInsets.all(8.0),
  //                           child: Container(
  //                             decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _getColor(snapshot2.data!, true), width: 15)),
  //                             child: Container(
  //                               decoration: BoxDecoration(
  //                                   color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _getColor(snapshot2.data!, true).withOpacity(0.5), width: 10)),
  //                               child: Container(
  //                                 width: MediaQuery
  //                                     .of(context)
  //                                     .size
  //                                     .width / 1.5,
  //                                 height: 300,
  //                                 decoration: BoxDecoration(
  //                                     color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _getColor(snapshot2.data!, true).withOpacity(0.3), width: 5)),
  //                                 child: Column(
  //                                   mainAxisSize: MainAxisSize.max,
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     SizedBox(
  //                                       width: 150,
  //                                       height: 150,
  //                                       child: Hero(
  //                                         tag: image,
  //                                         child: CachedNetworkImage(
  //                                           imageUrl: image,
  //                                           progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
  //                                           errorWidget: (context, url, error) => Icon(Icons.error),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     Padding(
  //                                       padding: const EdgeInsets.all(8.0),
  //                                       child: Text(
  //                                         "${item.name}",
  //                                         textAlign: TextAlign.center,
  //                                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       );
  //                     } else {
  //                       return CircularProgressIndicator();
  //                     }
  //                   });
  //             }
  //           }),
  //     );
  //   } else {
  //     return CircularProgressIndicator();
  //   }
  // }

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
