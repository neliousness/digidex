import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final dio = Dio(); // Provide a dio instance// config your dio headers globally
  late RestClient client;
  Map<String, PaletteGenerator> paletteMap = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    dio.options.headers["Demo-Header"] = "demo header"; // config your dio headers globally
    client = RestClient(dio);
  }

  @override
  Widget build(BuildContext context) {
    // use block pattern
    return Scaffold(
      appBar: AppBar(
        title: Text("DigiDex"),
        centerTitle: true,
      ),
      body: Center(
        child: FutureBuilder<Content>(
            future: client.getAllDigimon(),
            builder: (context, AsyncSnapshot<Content> snapshot) {
              if (snapshot.hasError) {
                return const Text("error");
              } else {
                return ListWheelScrollView.useDelegate(
                  itemExtent: 350,
                  squeeze: 1.1,
                  physics: const FixedExtentScrollPhysics(),
                  perspective: 0.0013,
                  onSelectedItemChanged: (index) => print(index),
                  childDelegate: ListWheelChildBuilderDelegate(
                      childCount: snapshot.data?.content?.length, builder: (context, index) => cardView(Digimon.$DigimonFromJson(snapshot.data?.content?[index]))),
                );
              }
            }),
      ),
    );
  }

  cardView(Digimon? item) {
    if (item != null && item.id! > -1) {
      return Center(
        child: FutureBuilder<DigimonDetails>(
            future: client.getDigimon("${item.id}"),
            builder: (context, AsyncSnapshot<DigimonDetails> snapshot) {
              if (snapshot.hasError) {
                return CircularProgressIndicator(value: 0);
              } else {
                print(snapshot.data);
                final image = snapshot.data?.images?[0]['href'];
                return FutureBuilder<PaletteGenerator?>(
                    future: !paletteMap.containsKey(image) ? _generatePalette(snapshot.data) : _localGen(image),
                    builder: (context, AsyncSnapshot<PaletteGenerator?> snapshot2) {
                      if (snapshot2.hasError) {
                        return CircularProgressIndicator(value: 0);
                      } else if (snapshot2.hasData) {
                        paletteMap[image] = snapshot2.data!;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: snapshot2.data!.vibrantColor!.color, width: 15)),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: snapshot2.data!.darkMutedColor!.color, width: 10)),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 1.5,
                                height: 300,
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: snapshot2.data!.vibrantColor!.color, width: 5)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: CachedNetworkImage(
                                        imageUrl: image,
                                        progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                                        errorWidget: (context, url, error) => Icon(Icons.error),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "${item.name}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return CircularProgressIndicator(value: 0);
                      }
                    });
              }
            }),
      );
    } else {
      return CircularProgressIndicator(value: 0);
    }
  }

  Future<PaletteGenerator?> _generatePalette(DigimonDetails? details) async {
    String href = details?.images?[0]['href'];
    NetworkImage image = NetworkImage(href);
    return await PaletteGenerator.fromImageProvider(
      image,
      region: Offset.zero & Size(250, 250),
      size: Size(250, 250),
      maximumColorCount: 20,
    );
  }

  Future<PaletteGenerator?> _localGen(String href) async {
    return paletteMap[href];
  }
}
