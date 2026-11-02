import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/content.dart';
import '../models/digimon_details.dart';
import '../models/lookup.dart';

part 'rest_client.g.dart';

@RestApi(baseUrl: "https://digi-api.com/api/v1")
abstract class RestClient {
  factory RestClient(Dio dio, {String? baseUrl}) = _RestClient;

  /// The list items carry id, name and image. Null filters are left out of
  /// the request; [name] matches anywhere in the name. The API's default
  /// page size is 5.
  @GET("/digimon")
  Future<Content> getPaginatedDigimon(
    @Query("page") int page, {
    @Query("pageSize") int? pageSize,
    @Query("name") String? name,
    @Query("attribute") String? attribute,
    @Query("level") String? level,
    @Query("xAntibody") bool? xAntibody,
  });

  @GET("/digimon/{id}")
  Future<DigimonDetails> getDigimon(@Path("id") String id);

  @GET("/level")
  Future<LookupPage> getLevels(@Query("page") int page);

  @GET("/attribute")
  Future<LookupPage> getAttributes(@Query("page") int page);
}
