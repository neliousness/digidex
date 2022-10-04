import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Content {
  List<dynamic>? content;
  dynamic pageable;

  Content({this.content, this.pageable});

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);

  static _$ContentFromJson(Map<String, dynamic> json) {
    return Content(content: json['content'], pageable: json['pageable']);
  }
}