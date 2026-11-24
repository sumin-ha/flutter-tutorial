import 'package:material_ui/material_ui.dart';

import 'bookmark.dart';

const ink = Color(0xFF242624);
const mutedInk = Color(0xFF787B77);
const accent = Color(0xFFEB633D);
const softLine = Color(0xFFEEEFEA);

class FoodThumbnail extends StatelessWidget {
  final Bookmark bookmark;
  final double size;
  const FoodThumbnail({super.key, required this.bookmark, this.size = 76});

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: const Color(0xFFF4EFE8),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: size * .32,
          color: const Color(0xFFC3AC94),
        ),
      ),
    );
    return Semantics(
      label: '${bookmark.title} 음식 사진',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox.square(
          dimension: size,
          child: bookmark.thumbnailUrl.isNotEmpty
              ? Image.network(
                  bookmark.thumbnailUrl,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => placeholder,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : placeholder,
                )
              : bookmark.thumbnailAsset != null
              ? Image.asset(
                  bookmark.thumbnailAsset!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => placeholder,
                )
              : placeholder,
        ),
      ),
    );
  }
}

class BookmarkTags extends StatelessWidget {
  final List<String> tags;
  final int? limit;
  const BookmarkTags({super.key, required this.tags, this.limit});

  @override
  Widget build(BuildContext context) {
    final shown = limit == null ? tags : tags.take(limit!).toList();
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...shown.map(
          (t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              t.startsWith('#') ? t : '#$t',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF767A70)),
            ),
          ),
        ),
        if (shown.length < tags.length)
          Text(
            '+${tags.length - shown.length}',
            style: const TextStyle(fontSize: 11, color: mutedInk),
          ),
      ],
    );
  }
}

class BookmarkSummary extends StatelessWidget {
  final Bookmark bookmark;
  final Widget? trailing;
  const BookmarkSummary({super.key, required this.bookmark, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FoodThumbnail(bookmark: bookmark),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bookmark.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: mutedInk),
            ),
            const SizedBox(height: 6),
            Text(
              bookmark.description.isEmpty
                  ? '기억하고 싶은 맛집'
                  : bookmark.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF555952),
              ),
            ),
            if (bookmark.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              BookmarkTags(tags: bookmark.tags, limit: 3),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}
