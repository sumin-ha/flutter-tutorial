import 'package:flutter_test/flutter_test.dart';
import 'package:foodmarks/bookmark.dart';
import 'package:foodmarks/bookmark_store.dart';
import 'package:foodmarks/repository.dart';

void main() {
  test('repository CRUD and combined filters', () async {
    final store = BookmarkStore(DemoRepository());
    await store.load();
    expect(store.items, hasLength(3));
    store.filter('혼밥');
    store.search('국밥');
    expect(store.visible, hasLength(1));
    final old = store.visible.single;
    await store.save(
      BookmarkDraft(
        title: '수정된 국밥',
        snsUrl: old.snsUrl,
        description: old.description,
        address: old.address,
        placeId: old.placeId,
        tags: old.tags,
      ),
      id: old.id,
    );
    expect(store.visible.single.title, '수정된 국밥');
    await store.delete(old.id);
    expect(store.items, hasLength(2));
    expect(store.tag, isNull);
    store.dispose();
  });
}
