import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true).withOpacity(0.7)),
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                    painter: CurvePainter(),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: SizedBox(
                        width: 215,
                        height: 215,
                        child: Hero(
                          tag: widget.imageLink,
                          child: CachedNetworkImage(
                            imageUrl: widget.imageLink,
                            progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, left: 20),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Icon(
                          Icons.arrow_back,
                          color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)), width: 1), borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            widget.details!.types!.isNotEmpty ? "${widget.details?.types?[0]['type']}" : 'N/A',
                            style: TextStyle(color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            //Details
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorUtils.darken(_getColor(widget.paletteGenerator!, true).withOpacity(0.7)),
                    _getColor(widget.paletteGenerator!, true).withOpacity(0.2),
                  ],
                  begin: const FractionalOffset(1.0, 0.0),
                  end: const FractionalOffset(1.0, 1.0),
                  stops: [0.1, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Digimon name
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      "${widget.details!.name}",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  //attribs
                  Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          height: 150,
                          width: MediaQuery.of(context).size.width / 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset(
                                "assets/images/svgs/level.svg",
                                width: 40,
                                color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "Level",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.levels!.isNotEmpty ? "${widget.details?.levels?[0]['level']}" : "N/A",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          height: 150,
                          width: MediaQuery.of(context).size.width / 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset(
                                "assets/images/svgs/xantibody.svg",
                                width: 40,
                                color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "X-Antibody",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.xAntibody! ? "Yes" : "No",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                          ),
                          height: 150,
                          width: MediaQuery.of(context).size.width / 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset(
                                "assets/images/svgs/attribute.svg",
                                width: 40,
                                color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "Attribute",
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.attributes!.isNotEmpty ? "${widget.details?.attributes?[0]['attribute']}" : "N/A",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorUtils.darken(_getColor(widget.paletteGenerator!, true))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: DefaultTabController(
                      length: 4,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TabBar(
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorColor: Colors.white,
                              tabs: [
                                Tab(
                                  text: "About",
                                ),
                                Tab(
                                  text: "Skills",
                                ),
                                Tab(
                                  text: "Evolution",
                                ),
                                Tab(
                                  text: "Fields",
                                )
                              ],
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 2.5,
                            child: TabBarView(
                              children: [
                                //About
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height / 3,
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        widget.details!.descriptions!.isNotEmpty ? "${widget.details!.descriptions![1]["description"]}" : "N/A",
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                ),
                                Icon(Icons.directions_transit),
                                Icon(Icons.directions_bike),
                                Icon(Icons.directions_bike),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getColor(PaletteGenerator generator, bool isVibrant) {
    if (isVibrant) {
      if (generator.vibrantColor != null) {
        return generator.vibrantColor!.color;
      } else {
        if (generator.darkVibrantColor != null) {
          return generator.darkVibrantColor!.color;
        } else {
          return Colors.black;
        }
      }
    } else {
      if (generator.dominantColor != null) {
        return generator.dominantColor!.color;
      } else {
        return Colors.black;
      }
    }
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill; // Change this to fill

    var path = Path();

    path.moveTo(0, size.height * 0.80);
    path.quadraticBezierTo(size.width / 2, size.height / 0.85, size.width, size.height * 0.80);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
