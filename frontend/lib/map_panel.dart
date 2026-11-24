import 'dart:ui' as ui;

import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'bookmark.dart';
import 'bookmark_widgets.dart';

class MapPanel extends StatefulWidget {
  final List<Bookmark> items;
  final Bookmark? selected;
  final bool isDemo;
  final double topInset;
  final ValueChanged<String> onSelect;
  final ValueChanged<Bookmark> onOpen, onEdit, onDetails;
  const MapPanel({
    super.key,
    required this.items,
    required this.selected,
    required this.isDemo,
    required this.onSelect,
    required this.onOpen,
    required this.onEdit,
    required this.onDetails,
    this.topInset = 20,
  });
  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  GoogleMapController? controller;
  static const enabled = bool.fromEnvironment('MAPS_ENABLED');
  Map<String, BitmapDescriptor> markerIcons = {};
  int markerVersion = 0;
  List<Bookmark> get located =>
      widget.items.where((b) => b.hasLocation).toList();
  bool get mapEnabled => enabled && !widget.isDemo;

  @override
  void initState() {
    super.initState();
    if (mapEnabled) buildMarkers();
  }

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectionChanged = widget.selected?.id != oldWidget.selected?.id;
    final itemsChanged =
        widget.items.length != oldWidget.items.length ||
        widget.items.asMap().entries.any(
          (e) => !identical(e.value, oldWidget.items[e.key]),
        );
    if (mapEnabled && (selectionChanged || itemsChanged)) buildMarkers();
    if (selectionChanged || itemsChanged) {
      final b = widget.selected;
      if (b != null && b.hasLocation) {
        controller?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(b.latitude!, b.longitude!), 15),
        );
      } else if (mapEnabled) {
        fit();
      }
    }
  }

  Future<void> buildMarkers() async {
    final version = ++markerVersion;
    final icons = <String, BitmapDescriptor>{};
    for (final b in located) {
      final active = b.id == widget.selected?.id;
      final title = b.title.characters.length > 11
          ? '${b.title.characters.take(11)}…'
          : b.title;
      final text = TextPainter(
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = text.width + 30;
      const height = 38.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(3);
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(3, 3, width - 6, 30),
        const Radius.circular(16),
      );
      canvas.drawShadow(
        Path()..addRRect(pill),
        const Color(0x44000000),
        3,
        true,
      );
      canvas.drawRRect(pill, Paint()..color = active ? ink : Colors.white);
      text.paint(canvas, const Offset(15, 9));
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * 3).ceil(),
        (height * 3).ceil(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        icons[b.id] = BitmapDescriptor.bytes(
          bytes.buffer.asUint8List(),
          imagePixelRatio: 3,
          width: width,
          height: height,
        );
      }
      image.dispose();
      picture.dispose();
      text.dispose();
      if (!mounted || version != markerVersion) return;
    }
    if (mounted && version == markerVersion) {
      setState(() => markerIcons = icons);
    }
  }

  Future<void> fit() async {
    final points = located;
    final c = controller;
    if (points.isEmpty || c == null) return;
    final lats = points.map((b) => b.latitude!).toList()..sort();
    final lngs = points.map((b) => b.longitude!).toList()..sort();
    if (lats.first == lats.last && lngs.first == lngs.last) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lats.first, lngs.first), 14),
      );
      return;
    }
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(lats.first, lngs.first),
          northeast: LatLng(lats.last, lngs.last),
        ),
        60,
      ),
    );
  }

  @override
  void dispose() {
    markerVersion++;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.selected;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardMaxHeight = (constraints.maxHeight * .48).clamp(100.0, 270.0);
        return ColoredBox(
          color: const Color(0xFFECF0E8),
          child: Stack(
            children: [
              Positioned.fill(
                child: mapEnabled
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: b?.hasLocation == true
                              ? LatLng(b!.latitude!, b.longitude!)
                              : const LatLng(36.4, 127.8),
                          zoom: b?.hasLocation == true ? 14 : 7,
                        ),
                        style: '''[
            {"featureType":"poi","stylers":[{"visibility":"off"}]},
            {"featureType":"transit","stylers":[{"visibility":"off"}]},
            {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cbdfe0"}]},
            {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#edf1e8"}]}
          ]''',
                        padding: EdgeInsets.only(
                          top: widget.topInset + 44,
                          bottom: b != null ? cardMaxHeight + 20 : 100,
                          left: 16,
                          right: 16,
                        ),
                        onMapCreated: (c) {
                          controller = c;
                          if (b == null) fit();
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        markers: located
                            .map(
                              (place) => Marker(
                                markerId: MarkerId(place.id),
                                position: LatLng(
                                  place.latitude!,
                                  place.longitude!,
                                ),
                                anchor: const Offset(.5, .8),
                                zIndexInt: place.id == b?.id ? 1 : 0,
                                consumeTapEvents: true,
                                onTap: () => widget.onSelect(place.id),
                                icon:
                                    markerIcons[place.id] ??
                                    BitmapDescriptor.defaultMarkerWithHue(
                                      place.id == b?.id
                                          ? BitmapDescriptor.hueOrange
                                          : BitmapDescriptor.hueRed,
                                    ),
                              ),
                            )
                            .toSet(),
                      )
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          28,
                          widget.topInset + 50,
                          28,
                          b != null ? cardMaxHeight + 28 : 118,
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .75),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.map_outlined,
                                    size: 36,
                                    color: Color(0xFF8C9C7D),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  widget.isDemo
                                      ? '데모 모드 · 실제 지도 없음'
                                      : '지도를 연결하면 한눈에 보여요',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.isDemo
                                      ? '저장한 맛집을 눌러 미리 살펴보세요.'
                                      : '저장한 맛집의 위치를 지도에서 모아볼 수 있어요.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: mutedInk,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: widget.topInset,
                left: 20,
                child: PointerInterceptor(
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x22000000),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: mapEnabled && located.isNotEmpty ? fit : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              mapEnabled
                                  ? Icons.fit_screen_rounded
                                  : Icons.bookmark_outline,
                              size: 16,
                              color: ink,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              mapEnabled
                                  ? '전체 ${located.length}곳 보기'
                                  : '저장한 맛집 ${widget.items.length}곳',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (b != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 440,
                        maxHeight: cardMaxHeight,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x20000000),
                              blurRadius: 26,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: PointerInterceptor(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  12,
                                  8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => widget.onDetails(b),
                                      child: BookmarkSummary(bookmark: b),
                                    ),
                                    const SizedBox(height: 6),
                                    const Divider(height: 1, color: softLine),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => widget.onOpen(b),
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'SNS 원문',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () => widget.onEdit(b),
                                          child: const Text(
                                            '수정',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedInk,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: '맛집 상세 보기',
                                          onPressed: () => widget.onDetails(b),
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: ink,
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
                      ),
                    ),
                  ),
                ),
              if (b == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: PointerInterceptor(
                        child: Container(
                          height: widget.items.isEmpty ? 66 : 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 20,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: widget.items.isEmpty
                              ? const Center(
                                  child: Text(
                                    '조건에 맞는 맛집이 없어요.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: mutedInk,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.all(14),
                                  itemCount: widget.items.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (_, i) {
                                    final item = widget.items[i];
                                    return SizedBox(
                                      width: 235,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () => widget.onSelect(item.id),
                                        child: Row(
                                          children: [
                                            FoodThumbnail(
                                              bookmark: item,
                                              size: 58,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    '눌러서 살펴보기',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: mutedInk,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
