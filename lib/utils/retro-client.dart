import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

import '../models/content.dart';
import '../models/digimon_details.dart';

part 'retro-client.g.dart';

@RestApi(baseUrl: "https://digi-api.com/api/v1")
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET("/digimon")
  Future<Content> getPaginatedDigimon(@Query("page") int page);

  @GET("/digimon/{id}")
  Future<DigimonDetails> getDigimon(@Path("id") String id);
}









