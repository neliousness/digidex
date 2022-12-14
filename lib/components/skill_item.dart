import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SkillItem extends StatefulWidget {
  final String name;
  final String description;
  final Color themeColor;

  const SkillItem({Key? key, this.name = "", this.description = "", required this.themeColor}) : super(key: key);

  @override
  _SkillItemState createState() => _SkillItemState();
}

class _SkillItemState extends State<SkillItem> {
  bool collapsed = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          collapsed = !collapsed;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: SvgPicture.asset(
                            "assets/images/svgs/skill.svg",
                            width: 35,
                            color: widget.themeColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            widget.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    Visibility(
                        visible: !collapsed,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 15),
                          child: Text(
                            widget.description,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ))
                  ],
                ),
                Align(alignment: Alignment.topRight, child: collapsed ? Icon(Icons.keyboard_arrow_down_rounded) : Icon(Icons.keyboard_arrow_up_rounded))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
