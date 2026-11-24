import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'bookmark.dart';
import 'bookmark_store.dart';
import 'bookmark_widgets.dart';
import 'editor.dart';
import 'map_panel.dart';
import 'repository.dart';

class HomeScreen extends StatefulWidget {
  final BookmarkStore store;
  const HomeScreen({super.key, required this.store});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  BookmarkStore get store => widget.store;
  Future<void> edit([Bookmark? bookmark]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PointerInterceptor(
        child: BookmarkEditor(store: store, bookmark: bookmark),
      ),
    );
    if (saved == true && mounted) message('수첩에 저장했어요.');
  }

  void message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  Future<void> delete(Bookmark b) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('북마크를 삭제할까요?'),
        content: Text('“${b.title}”이 수첩에서 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await store.delete(b.id);
      if (mounted) message('삭제했어요.');
    } catch (e) {
      if (mounted) message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> open(Bookmark b) async {
    try {
      if (!await launchUrl(
        Uri.parse(b.snsUrl),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) message('링크를 열 수 없습니다.');
      }
    } catch (_) {
      if (mounted) message('링크를 열 수 없습니다.');
    }
  }

  void showDetails(Bookmark b) {
    store.select(b.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) => PointerInterceptor(
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FoodThumbnail(bookmark: b, size: 84),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '내 수첩에 저장한 맛집',
                              style: TextStyle(fontSize: 12, color: mutedInk),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (b.tags.isNotEmpty) ...[
                    BookmarkTags(tags: b.tags),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    '기억할 메모',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.description.isEmpty ? '아직 메모가 없어요.' : b.description,
                    style: const TextStyle(
                      height: 1.7,
                      color: Color(0xFF5D625A),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: mutedInk,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.address,
                          style: const TextStyle(color: mutedInk, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                  if (!b.hasLocation)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '위치를 갱신하면 지도에 표시할 수 있어요.',
                        style: TextStyle(fontSize: 12, color: mutedInk),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() => tab = 1);
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('지도에서 보기'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => open(b),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('SNS 원문'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          edit(b);
                        },
                        child: const Text('수정'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          delete(b);
                        },
                        child: const Text(
                          '삭제',
                          style: TextStyle(color: mutedInk),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 960;
      final isDemo = store.repository is DemoRepository;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: wide ? 80 : 64,
          titleSpacing: wide ? 28 : 20,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '한입 수첩',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              if (wide) ...[
                const SizedBox(width: 20),
                const Text(
                  '가보고 싶은 곳, 한곳에.',
                  style: TextStyle(fontSize: 12, color: mutedInk),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              tooltip: '새로고침',
              onPressed: store.loading ? null : store.load,
              icon: const Icon(Icons.refresh_rounded, size: 21),
            ),
            if (wide) ...[
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => edit(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('맛집 저장'),
              ),
            ],
            SizedBox(width: wide ? 28 : 12),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: softLine),
          ),
        ),
        floatingActionButton: wide || tab == 1
            ? null
            : FloatingActionButton.extended(
                onPressed: () => edit(),
                icon: const Icon(Icons.add, size: 21),
                label: const Text(
                  '맛집 저장',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
        bottomNavigationBar: wide
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: softLine)),
                ),
                child: NavigationBar(
                  selectedIndex: tab,
                  onDestinationSelected: (v) => setState(() => tab = v),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.bookmarks_outlined),
                      selectedIcon: Icon(Icons.bookmarks_rounded),
                      label: '내 수첩',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: '지도',
                    ),
                  ],
                ),
              ),
        body: SafeArea(
          child: Column(
            children: [
              if (isDemo || store.repository.demoGeocoding)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFCF7EC),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Color(0xFF998259),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isDemo
                              ? 'UI 데모 · 새로고침하면 저장한 내용이 초기화돼요.'
                              : '주소 검색 체험 모드 · 서울·부산의 예시 위치를 제공해요.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF998259),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (store.loading) const LinearProgressIndicator(minHeight: 2),
              if (store.error != null)
                MaterialBanner(
                  content: Text(store.error!),
                  actions: [
                    TextButton(
                      onPressed: store.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 410, child: collection()),
                          const VerticalDivider(width: 1, color: softLine),
                          Expanded(child: map()),
                        ],
                      )
                    : tab == 0
                    ? collection()
                    : Stack(
                        children: [
                          Positioned.fill(child: map(topInset: 88)),
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: searchBox(floating: true),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget searchBox({bool floating = false}) => PointerInterceptor(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(floating ? 28 : 14),
        boxShadow: floating
            ? const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        key: ValueKey('search-$floating'),
        controller: searchController,
        onChanged: store.search,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: '어떤 맛집을 찾고 있나요?',
          hintStyle: const TextStyle(color: mutedInk, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 21, color: ink),
          suffixIcon: store.query.isEmpty
              ? null
              : IconButton(
                  tooltip: '검색 지우기',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    searchController.clear();
                    store.search('');
                  },
                ),
          fillColor: floating ? Colors.white : const Color(0xFFF6F7F3),
          border: floating
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                )
              : null,
          enabledBorder: floating
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                )
              : null,
        ),
      ),
    ),
  );

  Widget collection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '차곡차곡, 나의 맛집',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -.8,
                color: ink,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '다음 한 끼가 기대되는 곳들을 모았어요.',
              style: TextStyle(fontSize: 12, color: mutedInk),
            ),
            const SizedBox(height: 20),
            searchBox(),
          ],
        ),
      ),
      if (store.tags.isNotEmpty)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              filterPill('전체', null),
              ...store.tags.map((tag) => filterPill(tag, tag)),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Row(
          children: [
            const Text(
              '저장한 맛집',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${store.visible.length}',
              style: const TextStyle(
                fontSize: 12,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Text(
              '최근 저장순',
              style: TextStyle(fontSize: 11, color: mutedInk),
            ),
          ],
        ),
      ),
      Expanded(child: list()),
    ],
  );

  Widget filterPill(String label, String? value) {
    final selected = store.tag == value;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: FilterChip(
        label: Text(label, maxLines: 1, softWrap: false),
        selected: selected,
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : const Color(0xFF676C62),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
        selectedColor: ink,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? ink : const Color(0xFFE5E7DF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onSelected: (_) => store.filter(selected ? null : value),
      ),
    );
  }

  Widget map({double topInset = 20}) => MapPanel(
    items: store.visible,
    selected: store.selected,
    isDemo: store.repository.demoGeocoding,
    topInset: topInset,
    onSelect: store.select,
    onOpen: open,
    onEdit: edit,
    onDetails: showDetails,
  );

  Widget list() {
    final items = store.visible;
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F4EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_add_outlined,
                  size: 34,
                  color: accent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                store.loading
                    ? '수첩을 불러오고 있어요…'
                    : store.items.isEmpty
                    ? '첫 번째 맛집을 저장해보세요.'
                    : '검색 결과가 없어요.',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                store.items.isEmpty
                    ? '발견한 맛집을 나만의 메모와 함께 남겨보세요.'
                    : '다른 검색어나 태그를 선택해주세요.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: mutedInk,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, color: softLine),
      ),
      itemBuilder: (context, i) {
        final b = items[i];
        return Material(
          color: store.selectedId == b.id
              ? const Color(0xFFFFF8F4)
              : Colors.white,
          child: InkWell(
            onTap: () => showDetails(b),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: BookmarkSummary(
                bookmark: b,
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      tooltip: '북마크 메뉴',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_horiz,
                        size: 19,
                        color: mutedInk,
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') edit(b);
                        if (value == 'delete') delete(b);
                        if (value == 'open') open(b);
                        if (value == 'refresh') {
                          try {
                            await store.refresh(b.id);
                          } catch (e) {
                            if (mounted) message('$e');
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Text('SNS 원문'),
                        ),
                        const PopupMenuItem(value: 'edit', child: Text('수정')),
                        const PopupMenuItem(value: 'delete', child: Text('삭제')),
                        if (!b.hasLocation)
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Text('위치 갱신'),
                          ),
                      ],
                    ),
                    IconButton(
                      tooltip: '지도에서 보기',
                      onPressed: () {
                        store.select(b.id);
                        setState(() => tab = 1);
                      },
                      icon: const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
