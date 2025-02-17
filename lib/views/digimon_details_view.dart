import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/behavior/behavior.dart';
import 'package:digidexplus/components/field_item.dart';
import 'package:digidexplus/components/skill_item.dart';
import 'package:digidexplus/utils/color_utils.dart';
import 'package:digidexplus/utils/constants.dart';
import 'package:digidexplus/utils/digimon_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palette_generator/palette_generator.dart';

import '../components/evolution_item.dart';
import '../models/digimon_details.dart';
import '../utils/curve_painter.dart';
import '../utils/retro-client.dart';

class DigimonDetailsView extends StatefulWidget {
  final PaletteGenerator? paletteGenerator;
  final DigimonDetails? details;
  final String? imageLink;
  final RestClient client;

  const DigimonDetailsView({Key? key, required this.paletteGenerator, required this.details, required this.imageLink, required this.client}) : super(key: key);

  @override
  _DigimonDetailsViewState createState() => _DigimonDetailsViewState();
}

class _DigimonDetailsViewState extends State<DigimonDetailsView> {
  List<SkillItem>? _skills;
  List<FieldItem>? _fields;
  List<EvolutionItem>? _evolutions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.9)),
              height: MediaQuery.of(context).size.height / 2.8,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            flex: 3,
                            child: SizedBox(
                              width: 215,
                              height: 215,
                              child: Hero(
                                tag: widget.imageLink!,
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageLink!,
                                  progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16, top: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)), width: 1),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    widget.details!.types!.isNotEmpty ? "${widget.details?.types?[0]['type']}" : kNA,
                                    style: TextStyle(color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
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
                        child: SvgPicture.asset(kBackArrow, width: 30, color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //Details
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.9)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Digimon name
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, left: 8, right: 8),
                        child: Text(
                          "${widget.details!.name}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 7.0, left: MediaQuery.of(context).size.width / 2.8, right: MediaQuery.of(context).size.width / 2.8),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 3,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    ],
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
                                color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "Level",
                                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.levels!.isNotEmpty ? "${widget.details?.levels?[0]['level']}" : "N/A",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
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
                                "assets/images/svgs/mass.svg",
                                width: 40,
                                color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "X-Antibody",
                                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.xAntibody! ? "Yes" : "No",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
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
                                color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)),
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "Attribute",
                                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    widget.details!.attributes!.isNotEmpty ? "${widget.details?.attributes?[0]['attribute']}" : "N/A",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //About
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                        child: Column(
                          spacing: 10,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "About",
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Text(
                                  DigimonUtils.getDescription(widget.details!.descriptions!, "en_us"),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Abilities
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 25, left: 0, right: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 0, bottom: 0, left: 20, right: 20),
                              child: Text(
                                "Abilities",
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 0.0),
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.16,
                                child: FutureBuilder(
                                    future: _generateSkills(),
                                    builder: (context, AsyncSnapshot<List<SkillItem>?> snapshot) {
                                      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                                        return ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.only(left: 20),
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return snapshot.data![index];
                                          },
                                        );
                                      } else {
                                        return Padding(
                                          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 3, top: 50),
                                          child: const Text("No Skills available"),
                                        );
                                      }
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Evolutions
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 25, left: 0, right: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Text(
                                "Evolutions",
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.16,
                              child: FutureBuilder(
                                  future: _generateEvolutions(),
                                  builder: (context, AsyncSnapshot<List<EvolutionItem>?> snapshot) {
                                    if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                                      return ScrollConfiguration(
                                        behavior: MyBehavior(),
                                        child: ListView.builder(
                                          padding: const EdgeInsets.only(left: 20.0),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _evolutions?.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return _evolutions![index];
                                          },
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 3, top: 50),
                                        child: const Text("No Evolutions available"),
                                      );
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ),
                      //Fields
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 25, left: 0, right: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Text(
                                "Fields",
                                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.16,
                              child: FutureBuilder(
                                  future: _generateFields(),
                                  builder: (context, AsyncSnapshot<List<FieldItem>?> snapshot) {
                                    if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                                      return ListView.builder(
                                        shrinkWrap: false,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _fields?.length,
                                        itemBuilder: (BuildContext context, int index) {
                                          return _fields![index];
                                        },
                                      );
                                    } else {
                                      return Padding(
                                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 3, top: 50),
                                        child: const Text("No Fields available"),
                                      );
                                    }
                                  }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<List<SkillItem>?> _generateSkills() async {
    if (_skills == null) {
      _skills = widget.details!.skills!
          .map((element) =>
              SkillItem(name: element['skill'], description: element['description'], themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))))
          .toList();
      return _skills;
    }
    return _skills;
  }

  Future<List<FieldItem>?> _generateFields() async {
    if (_fields == null) {
      _fields = widget.details!.fields!
          .map(
            (element) => FieldItem(name: element['field'], themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
          )
          .toList();
      return _fields;
    }
    return _fields;
  }

  Future<List<EvolutionItem>?> _generateEvolutions() async {
    if (_evolutions == null) {
      List<EvolutionItem> nextEvolutions = [];
      if (widget.details!.nextEvolutions!.isNotEmpty) {
        nextEvolutions = widget.details!.nextEvolutions!
            .where((element) => DigimonUtils.isValidEvolution(element))
            .map(
              (element) => EvolutionItem(
                  client: widget.client,
                  name: element[kDigimon],
                  isNextEvolution: true,
                  id: element[kId],
                  themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
            )
            .toList();
      }

      List<EvolutionItem> priorEvolutions = [];
      if (widget.details!.priorEvolutions!.isNotEmpty) {
        priorEvolutions = widget.details!.priorEvolutions!
            .where((element) => DigimonUtils.isValidEvolution(element))
            .map(
              (element) => EvolutionItem(
                  client: widget.client,
                  name: element[kDigimon],
                  isNextEvolution: false,
                  id: element[kId],
                  themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
            )
            .toList();
      }

      _evolutions = nextEvolutions + priorEvolutions;
      return _evolutions;
    }
    return _evolutions;
  }
}
