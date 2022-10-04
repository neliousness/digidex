import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class Pageable {
  int? currentPage;
  int? elementsOnPage;
  int? totalElements;
  int? totalPages;
  String? previousPage;
  String? nextPage;
}
