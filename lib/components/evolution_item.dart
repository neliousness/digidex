import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:digidexplus/utils/retro-client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/digimon_details.dart';
import '../views/digimon_details_view.dart';

class EvolutionItem extends StatefulWidget {
  final String name;
  final Color themeColor;
  final bool isNextEvolution;
  final int id;
  final RestClient client;

  const EvolutionItem({Key? key, required this.name, required this.themeColor, required this.isNextEvolution, this.id = 0, required this.client}) : super(key: key);

  @override
  _EvolutionItemState createState() => _EvolutionItemState();
}

class _EvolutionItemState extends State<EvolutionItem> {
  DigimonDetails? _details;
  String? _image;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FutureBuilder(
                    future: DigimonUtils.generatePalette(_details),
                    builder: (context, AsyncSnapshot<PaletteGenerator?> snapshot) {
                      if (snapshot.hasData) {
                        return DigimonDetailsView(
                          paletteGenerator: snapshot.data,
                          imageLink: _image!,
                          details: _details,
                          client: widget.client,
                        );
                      } else {
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    })));
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 0.0, right: 10.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(17.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(17.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: RotatedBox(
                              quarterTurns: widget.isNextEvolution ? 1 : -1,
                              child: SvgPicture.asset(
                                "assets/images/svgs/up_arrow.svg",
                                width: 35,
                                color: widget.themeColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              DigimonUtils.formattedName(widget.name),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: widget.themeColor.withOpacity(0.5), width: 2)),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: widget.themeColor, width: 2)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: FutureBuilder(
                              future: widget.client.getDigimon("${widget.id}"),
                              builder: (context, AsyncSnapshot<DigimonDetails?> snapshot) {
                                if (snapshot.hasData) {
                                  _image = snapshot.data?.images?[0]['href'];
                                  _details = snapshot.data;
                                  return Hero(
                                    tag: _image!,
                                    child: CachedNetworkImage(
                                      imageUrl: _image!,
                                      progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                                      errorWidget: (context, url, error) => Icon(Icons.error),
                                    ),
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              }),
                        ),
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
