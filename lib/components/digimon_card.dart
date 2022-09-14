import 'package:cached_network_image/cached_network_image.dart';
import 'package:digidexplus/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../utils/retro-client.dart';
import '../views/digimon_details_view.dart';

class DigimonCard extends StatefulWidget {
  final PaletteGenerator? paletteGenerator;
  final DigimonDetails? details;
  final String? imageLink;
  final RestClient client;

  const DigimonCard({Key? key, this.paletteGenerator, this.details, this.imageLink, required this.client}) : super(key: key);

  @override
  _DigimonCardState createState() => _DigimonCardState();
}

class _DigimonCardState extends State<DigimonCard> {
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DigimonDetailsView(
                      paletteGenerator: widget.paletteGenerator,
                      imageLink: widget.imageLink,
                      details: widget.details,
                      client: widget.client,
                    )));
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ColorUtils.getColor(widget.paletteGenerator!, true), width: 15)),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.5), width: 10)),
            child: Container(
              width: MediaQuery.of(context).size.width / 1.5,
              height: 300,
              decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ColorUtils.getColor(widget.paletteGenerator!, true).withOpacity(0.3), width: 5)),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: Hero(
                      tag: widget.imageLink!,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageLink!,
                        progressIndicatorBuilder: (context, url, downloadProgress) => CircularProgressIndicator(value: downloadProgress.progress),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${widget.details!.name}",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    ;
  }
}
