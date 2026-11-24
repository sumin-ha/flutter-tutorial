class PlaceCandidate {
  final String placeId, label;
  final double latitude, longitude;
  const PlaceCandidate(this.placeId, this.label, this.latitude, this.longitude);
  factory PlaceCandidate.fromJson(Map<String, dynamic> j) => PlaceCandidate(
    j['placeId'] as String,
    j['label'] as String,
    (j['latitude'] as num).toDouble(),
    (j['longitude'] as num).toDouble(),
  );
}

class Bookmark {
  final String id, title, snsUrl, description, address, placeId;
  final String thumbnailUrl;
  final String? thumbnailAsset;
  final List<String> tags;
  final double? latitude, longitude;
  final DateTime createdAt, updatedAt;
  final DateTime? coordinatesExpireAt;
  const Bookmark({
    required this.id,
    required this.title,
    required this.snsUrl,
    required this.description,
    required this.address,
    required this.placeId,
    required this.tags,
    this.thumbnailUrl = '',
    this.thumbnailAsset,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.coordinatesExpireAt,
  });
  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      (coordinatesExpireAt == null ||
          coordinatesExpireAt!.isAfter(DateTime.now()));
  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
    id: j['id'],
    title: j['title'],
    snsUrl: j['snsUrl'],
    thumbnailUrl: j['thumbnailUrl'] ?? '',
    description: j['description'],
    address: j['address'],
    placeId: j['placeId'],
    tags: List<String>.from(j['tags']),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
    coordinatesExpireAt: DateTime.tryParse(j['coordinatesExpireAt'] ?? ''),
  );
}

class BookmarkDraft {
  final String title, snsUrl, description, address, placeId;
  final String thumbnailUrl;
  final List<String> tags;
  const BookmarkDraft({
    required this.title,
    required this.snsUrl,
    required this.description,
    required this.address,
    required this.placeId,
    required this.tags,
    this.thumbnailUrl = '',
  });
  Map<String, dynamic> toJson() => {
    'title': title,
    'snsUrl': snsUrl,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
    'address': address,
    'placeId': placeId,
    'tags': tags,
  };
}
