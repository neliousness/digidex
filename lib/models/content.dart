class Content {
  List<dynamic>? content;
  dynamic pageable;

  Content({this.content, this.pageable});

  factory Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);

  static Content _$ContentFromJson(Map<String, dynamic> json) {
    return Content(content: json['content'], pageable: json['pageable']);
  }

  /// How many Digimon match in total (all pages), if the API says.
  int? get totalElements {
    if (pageable is Map) {
      final total = pageable['totalElements'];
      if (total is int) return total;
    }
    return null;
  }

  /// False once the API reports there is no next page.
  bool get hasNextPage {
    if (pageable is Map) {
      final next = pageable['nextPage'];
      return next != null && '$next'.isNotEmpty;
    }
    return content?.isNotEmpty ?? false;
  }
}
