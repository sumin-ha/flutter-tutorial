import 'dart:convert';

import 'package:http/http.dart' as http;

import 'bookmark.dart';

abstract class BookmarkRepository {
  bool get demoGeocoding;
  Future<List<Bookmark>> load();
  Future<List<PlaceCandidate>> searchAddress(String address);
  Future<void> save(BookmarkDraft draft, {String? id});
  Future<void> delete(String id);
  Future<void> refreshLocation(String id);
  void dispose() {}
}

class ApiRepository implements BookmarkRepository {
  final String baseUrl;
  final http.Client _client = http.Client();
  @override
  bool demoGeocoding = false;
  ApiRepository(this.baseUrl);
  Future<dynamic> _request(String method, String path, [Object? body]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request),
      ).timeout(const Duration(seconds: 20));
      final data = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 400) {
        throw Exception(
          data is Map
              ? data['message'] ?? '요청 실패 (${response.statusCode})'
              : '요청 실패',
        );
      }
      return data;
    } on FormatException {
      throw Exception('서버 응답 형식을 확인해주세요. API_BASE_URL이 올바른가요?');
    } on http.ClientException {
      throw Exception('서버에 연결할 수 없습니다. API 주소와 서버 실행 상태를 확인해주세요.');
    }
  }

  @override
  Future<List<Bookmark>> load() async {
    final status = await _request('GET', '/status');
    demoGeocoding = status['geocodingMode'] == 'demo';
    return (await _request('GET', '/bookmarks') as List)
        .map((j) => Bookmark.fromJson(j))
        .toList();
  }

  @override
  Future<List<PlaceCandidate>> searchAddress(String address) async =>
      (await _request(
        'GET',
        '/geocode?address=${Uri.encodeQueryComponent(address)}',
      ) as List).map((j) => PlaceCandidate.fromJson(j)).toList();
  @override
  Future<void> save(BookmarkDraft draft, {String? id}) async {
    await _request(
      id == null ? 'POST' : 'PUT',
      '/bookmarks${id == null ? '' : '/$id'}',
      draft.toJson(),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _request('DELETE', '/bookmarks/$id');
  }

  @override
  Future<void> refreshLocation(String id) async {
    await _request('POST', '/bookmarks/$id/location');
  }

  @override
  void dispose() => _client.close();
}

// Explicit in-memory UI practice mode. Restarting the app resets this data.
class DemoRepository extends BookmarkRepository {
  @override
  bool get demoGeocoding => true;
  static const places = [
    PlaceCandidate(
      'demo-seoul-cityhall',
      '서울특별시 중구 세종대로 110 (데모 위치)',
      37.5663,
      126.9779,
    ),
    PlaceCandidate(
      'demo-seoul-station',
      '서울특별시 용산구 한강대로 405 (데모 위치)',
      37.5547,
      126.9706,
    ),
    PlaceCandidate(
      'demo-busan-cityhall',
      '부산광역시 연제구 중앙대로 1001 (데모 위치)',
      35.1796,
      129.0756,
    ),
  ];
  final List<Bookmark> _items = [];
  int _sequence = 0;
  DemoRepository() {
    for (var i = 0; i < 3; i++) {
      final p = places[i];
      _items.add(
        Bookmark(
          id: '${_sequence++}',
          title: ['골목의 작은 파스타집', '퇴근길 따뜻한 국밥', '주말에 가볼 카페'][i],
          snsUrl: 'https://www.instagram.com/',
          thumbnailAsset: [
            'assets/images/pasta.jpg',
            'assets/images/soup.jpg',
            'assets/images/coffee.jpg',
          ][i],
          description: [
            '바질 파스타가 궁금해서 저장. 다음 주 친구와 방문하기!',
            '혼자 가도 편안해 보이는 곳. 점심 메뉴 확인하기.',
            '커피와 디저트가 있는 느긋한 오후를 위해.',
          ][i],
          address: p.label.replaceAll(' (데모 위치)', ''),
          placeId: p.placeId,
          tags: [
            ['파스타', '데이트'],
            ['국밥', '혼밥'],
            ['카페', '주말'],
          ][i],
          latitude: p.latitude,
          longitude: p.longitude,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
  @override
  Future<List<Bookmark>> load() async => List.unmodifiable(_items);
  @override
  Future<List<PlaceCandidate>> searchAddress(String address) async => places
      .where(
        (p) =>
            p.label.contains(address) ||
            (address.contains('서울') && p.placeId.contains('seoul')) ||
            (address.contains('부산') && p.placeId.contains('busan')),
      )
      .toList();
  @override
  Future<void> save(BookmarkDraft draft, {String? id}) async {
    final p = places.firstWhere((p) => p.placeId == draft.placeId);
    final old = id == null ? null : _items.firstWhere((b) => b.id == id);
    final item = Bookmark(
      id: id ?? '${_sequence++}',
      title: draft.title,
      snsUrl: draft.snsUrl,
      thumbnailUrl: draft.thumbnailUrl,
      thumbnailAsset: draft.thumbnailUrl.isEmpty ? old?.thumbnailAsset : null,
      description: draft.description,
      address: draft.address,
      placeId: p.placeId,
      tags: draft.tags,
      latitude: p.latitude,
      longitude: p.longitude,
      createdAt: old?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _items.removeWhere((b) => b.id == id);
    _items.insert(0, item);
  }

  @override
  Future<void> delete(String id) async => _items.removeWhere((b) => b.id == id);
  @override
  Future<void> refreshLocation(String id) async {}
}
