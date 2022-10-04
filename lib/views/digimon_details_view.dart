import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/behavior/behavior.dart';
import 'package:digidexplus/components/field_item.dart';
import 'package:digidexplus/components/skill_item.dart';
import 'package:digidexplus/utils/color_utils.dart';
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
  List<SkillItem> _skills = [];
  List<FieldItem> _fields = [];
  List<EvolutionItem> _evolutions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.7)),
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
                          SizedBox(
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
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)), width: 1),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  widget.details!.types!.isNotEmpty ? "${widget.details?.types?[0]['type']}" : 'N/A',
                                  style: TextStyle(color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)), fontWeight: FontWeight.bold),
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
                        child: Icon(
                          Icons.arrow_back,
                          color: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true)),
                        ),
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
                gradient: LinearGradient(
                  colors: [
                    ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.7)),
                    ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.2),
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
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: DefaultTabController(
                      length: 4,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TabBar(
                              indicatorSize: TabBarIndicatorSize.label,
                              labelPadding: EdgeInsets.only(right: 0),
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
                            height: MediaQuery.of(context).size.height / 1.8,
                            child: TabBarView(
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                //About
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ScrollConfiguration(
                                    behavior: MyBehavior(),
                                    child: SingleChildScrollView(
                                      child: Container(
                                        width: MediaQuery.of(context).size.width,
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            DigimonUtils.getDescription(widget.details!.descriptions!, "en_us"),
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                //Skills
                                FutureBuilder(
                                    future: _generateSkills(),
                                    builder: (context, AsyncSnapshot<List<SkillItem>?> snapshot) {
                                      if (snapshot.hasData) {
                                        return ScrollConfiguration(
                                          behavior: MyBehavior(),
                                          child: ListView.builder(
                                            shrinkWrap: false,
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (BuildContext context, int index) {
                                              return snapshot.data![index];
                                            },
                                          ),
                                        );
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    }),
                                //Evolution
                                FutureBuilder(
                                    future: _generateEvolutions(),
                                    builder: (context, AsyncSnapshot<List<EvolutionItem>?> snapshot) {
                                      return ScrollConfiguration(
                                        behavior: MyBehavior(),
                                        child: ListView.builder(
                                          shrinkWrap: false,
                                          itemCount: _evolutions.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return _evolutions[index];
                                          },
                                        ),
                                      );
                                    }),
                                //Fields
                                FutureBuilder(
                                    future: _generateFields(),
                                    builder: (context, AsyncSnapshot<List<FieldItem>?> snapshot) {
                                      return ScrollConfiguration(
                                        behavior: MyBehavior(),
                                        child: ListView.builder(
                                          shrinkWrap: false,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _fields.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return _fields[index];
                                          },
                                        ),
                                      );
                                    }),
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

  Future<List<SkillItem>> _generateSkills() async {
    if (_skills.isEmpty) {
      _skills = widget.details!.skills!
          .map((element) =>
              SkillItem(name: element['skill'], description: element['description'], themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))))
          .toList();
      return _skills;
    }
    return _skills;
  }

  Future<List<FieldItem>> _generateFields() async {
    if (_fields.isEmpty) {
      _fields = widget.details!.fields!
          .map(
            (element) => FieldItem(name: element['field'], themeColor: ColorUtils.darken(ColorUtils.getColor(widget.paletteGenerator!, true))),
          )
          .toList();
      return _fields;
    }
    return _fields;
  }

  Future<List<EvolutionItem>> _generateEvolutions() async {
    if (_evolutions.isEmpty) {
      List<EvolutionItem> nextEvolutions = [];
      if (widget.details!.nextEvolutions!.isNotEmpty) {
        nextEvolutions = widget.details!.nextEvolutions!
            .where((element) => DigimonUtils.isValidEvolution(element))
            .map(
              (element) => EvolutionItem(
                  client: widget.client,
                  name: element['digimon'],
                  isNextEvolution: true,
                  id: element['id'],
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
                  name: element['digimon'],
                  isNextEvolution: false,
                  id: element['id'],
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
