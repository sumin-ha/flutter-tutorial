import 'package:flutter/foundation.dart';

import 'bookmark.dart';
import 'repository.dart';

class BookmarkStore extends ChangeNotifier {
  final BookmarkRepository repository;
  BookmarkStore(this.repository);
  List<Bookmark> items = [];
  bool loading = false;
  String? error, selectedId, tag;
  String query = '';
  Bookmark? get selected {
    for (final b in visible) {
      if (b.id == selectedId) return b;
    }
    return null;
  }

  List<String> get tags => items.expand((b) => b.tags).toSet().toList()..sort();
  List<Bookmark> get visible => items.where((b) {
    final text = '${b.title} ${b.description} ${b.address} ${b.tags.join(' ')}'
        .toLowerCase();
    return text.contains(query.toLowerCase().trim()) &&
        (tag == null || b.tags.contains(tag));
  }).toList();
  void search(String value) {
    query = value;
    notifyListeners();
  }

  void filter(String? value) {
    tag = value;
    notifyListeners();
  }

  void select(String id) {
    selectedId = id;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.load();
      if (tag != null && !tags.contains(tag)) tag = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> save(BookmarkDraft d, {String? id}) async {
    await repository.save(d, id: id);
    await load();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    if (selectedId == id) selectedId = null;
    await load();
  }

  Future<void> refresh(String id) async {
    await repository.refreshLocation(id);
    await load();
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
