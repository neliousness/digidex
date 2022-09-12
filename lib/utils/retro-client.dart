import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'retro-client.g.dart';

@RestApi(baseUrl: "https://digi-api.com/api/v1")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("/digimon")
  Future<Content> getPaginatedDigimon(@Query("page") int page);

  @GET("/digimon/{id}")
  Future<DigimonDetails> getDigimon(@Path("id") String id);
}

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

@JsonSerializable()
class Digimon {
  int? id;
  String? name;
  String? href;

  Digimon({this.id = -1, this.name = "N/A", this.href = "N/A"});

  @override
  bool operator ==(Object other) {
    return other != null && other is Digimon && hashCode == other.hashCode;
  }

  @override
  int get hashCode => id!;

  static $DigimonFromJson(dynamic json) {
    if (json != null) {
      return Digimon(id: json['id'], name: json['name'], href: json['href']);
    }
    return Digimon();
  }
}

@JsonSerializable()
class Pageable {
  int? currentPage;
  int? elementsOnPage;
  int? totalElements;
  int? totalPages;
  String? previousPage;
  String? nextPage;
}

@JsonSerializable()
class DigimonDetails {
  int? id;
  String? name;
  bool? xAntibody;
  List<dynamic>? images;
  List<dynamic>? types;
  List<dynamic>? levels;
  List<dynamic>? attributes;
  List<dynamic>? fields;
  List<dynamic>? descriptions;

  DigimonDetails({this.id, this.name, this.xAntibody, this.images, this.types, this.levels, this.attributes, this.fields, this.descriptions});

  factory DigimonDetails.fromJson(Map<String, dynamic> json) => $DigimonDetailsFromJson(json);

  static $DigimonDetailsFromJson(dynamic json) {
    if (json != null) {
      return DigimonDetails(
        id: json['id'],
        name: json['name'],
        xAntibody: json['xAntibody'],
        images: json['images'],
        types: json['types'],
        levels: json['levels'],
        attributes: json['attributes'],
        fields: json['fields'],
        descriptions: json['descriptions'],
      );
    }
    return DigimonDetails();
  }
}

@JsonSerializable()
class Image {
  String? href;
  bool? transparent;
}
