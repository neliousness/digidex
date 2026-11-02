/// An entry from a lookup endpoint such as /level or /attribute.
class Lookup {
  final int id;
  final String name;

  const Lookup(this.id, this.name);
}

/// One page of a lookup endpoint. The API nests the entries in
/// `content.fields` and returns no fields past the last page.
class LookupPage {
  final List<Lookup> items;
  final bool hasNextPage;

  const LookupPage(this.items, {required this.hasNextPage});

  factory LookupPage.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    final fields = content is Map ? content['fields'] : null;
    final items = <Lookup>[
      for (final field in fields is List ? fields : const [])
        if (field is Map && field['id'] is int && field['name'] is String) Lookup(field['id'], field['name']),
    ];
    final pageable = json['pageable'];
    final next = pageable is Map ? pageable['nextPage'] : null;
    return LookupPage(items, hasNextPage: items.isNotEmpty && next is String && next.isNotEmpty);
  }
}
