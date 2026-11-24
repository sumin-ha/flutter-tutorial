import 'package:material_ui/material_ui.dart';

import 'bookmark.dart';
import 'bookmark_store.dart';

class BookmarkEditor extends StatefulWidget {
  final BookmarkStore store;
  final Bookmark? bookmark;
  const BookmarkEditor({super.key, required this.store, this.bookmark});
  @override
  State<BookmarkEditor> createState() => _BookmarkEditorState();
}

class _BookmarkEditorState extends State<BookmarkEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title,
      url,
      description,
      tags,
      address,
      photo;
  PlaceCandidate? selected;
  List<PlaceCandidate> candidates = [];
  bool searching = false, saving = false;
  String? error;
  int searchVersion = 0;
  @override
  void initState() {
    super.initState();
    final b = widget.bookmark;
    title = TextEditingController(text: b?.title);
    url = TextEditingController(text: b?.snsUrl);
    photo = TextEditingController(text: b?.thumbnailUrl);
    description = TextEditingController(text: b?.description);
    tags = TextEditingController(text: b?.tags.join(', '));
    address = TextEditingController(text: b?.address);
    if (b != null) {
      selected = PlaceCandidate(
        b.placeId,
        b.address,
        b.latitude ?? 0,
        b.longitude ?? 0,
      );
    }
  }

  @override
  void dispose() {
    for (final c in [title, url, description, tags, address, photo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> search() async {
    if (address.text.trim().isEmpty) {
      setState(() => error = '도로명 주소를 입력해주세요.');
      return;
    }
    final version = ++searchVersion;
    final entered = address.text.trim();
    setState(() {
      searching = true;
      error = null;
      selected = null;
      candidates = [];
    });
    try {
      final result = await widget.store.repository.searchAddress(entered);
      if (!mounted || version != searchVersion) return;
      setState(() {
        candidates = result;
        if (result.isEmpty) error = '주소를 찾지 못했어요. 더 구체적인 도로명 주소를 입력해주세요.';
      });
    } catch (e) {
      if (mounted && version == searchVersion) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted && version == searchVersion) {
        setState(() => searching = false);
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (selected == null) {
      setState(() => error = '주소 검색 후 위치 후보를 선택해주세요.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.store.save(
        BookmarkDraft(
          title: title.text.trim(),
          snsUrl: url.text.trim(),
          thumbnailUrl: photo.text.trim(),
          description: description.text.trim(),
          address: address.text.trim(),
          placeId: selected!.placeId,
          tags: tags.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList(),
        ),
        id: widget.bookmark?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? '필수 입력입니다.' : null;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Text(widget.bookmark == null ? '새 맛집 저장' : '맛집 수정'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: title,
                  enabled: !saving,
                  maxLength: 100,
                  validator: requiredText,
                  decoration: const InputDecoration(
                    labelText: '맛집 이름 *',
                    hintText: '나중에 찾기 좋은 이름',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: url,
                  enabled: !saving,
                  maxLength: 2000,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final u = Uri.tryParse(value?.trim() ?? '');
                    return u == null ||
                            u.scheme != 'https' ||
                            u.host.isEmpty ||
                            u.userInfo.isNotEmpty
                        ? 'https://로 시작하는 SNS 주소를 입력해주세요.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'SNS 링크 *',
                    hintText: 'https://www.instagram.com/p/...',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: photo,
                  enabled: !saving,
                  maxLength: 2000,
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final u = Uri.tryParse(value.trim());
                    return u == null ||
                            u.scheme != 'https' ||
                            u.host.isEmpty ||
                            u.userInfo.isNotEmpty
                        ? 'https://로 시작하는 사진 주소를 입력해주세요.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: '음식 사진 URL (선택)',
                    hintText: 'https://…/food.jpg',
                    helperText: '사진이 없으면 기본 이미지로 표시해요.',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: description,
                  enabled: !saving,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '기억할 메모',
                    hintText: '먹고 싶은 메뉴, 방문할 시간…',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tags,
                  enabled: !saving,
                  decoration: const InputDecoration(
                    labelText: '태그',
                    helperText: '쉼표로 구분 · 최대 8개 · 태그당 20자',
                    hintText: '파스타, 데이트, 가고싶다',
                  ),
                  validator: (value) {
                    final values = (value ?? '')
                        .split(',')
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty)
                        .toSet();
                    return values.length > 8 || values.any((s) => s.length > 20)
                        ? '태그는 최대 8개, 각각 20자 이내로 입력해주세요.'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: address,
                  enabled: !saving,
                  maxLength: 300,
                  validator: requiredText,
                  onChanged: (_) {
                    searchVersion++;
                    setState(() {
                      selected = null;
                      candidates = [];
                      searching = false;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: '도로명 주소 *',
                    hintText: '서울특별시 중구 세종대로 110',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: searching || saving ? null : search,
                  icon: searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('주소 검색'),
                ),
                if (widget.store.repository.demoGeocoding)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '데모 검색: 서울 또는 부산을 입력하세요. 고정 위치 후보만 제공합니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (!widget.store.repository.demoGeocoding &&
                    candidates.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Google Maps',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ...candidates.map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected?.placeId == c.placeId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(c.label),
                    subtitle: const Text('이 위치로 저장하려면 선택하세요'),
                    onTap: saving ? null : () => setState(() => selected = c),
                  ),
                ),
                if (selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '✓ 위치 선택됨: ${selected!.label}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    ),
  );
}
