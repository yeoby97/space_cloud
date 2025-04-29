import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/warehouse.dart';
import 'favorite/favorite_button.dart';
import 'reservation_screen.dart';

class CustomBottomSheet extends StatefulWidget {
  final Warehouse warehouse;
  final VoidCallback onClose;
  final VoidCallback onTap;
  final bool isInitial;
  final ValueNotifier<bool> isOpenNotifier;

  const CustomBottomSheet({
    super.key,
    required this.warehouse,
    required this.onClose,
    required this.onTap,
    required this.isOpenNotifier,
    this.isInitial = true,
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> with SingleTickerProviderStateMixin {
  double _sheetHeight = 300;
  final double _minHeight = 0;
  final double _maxHeight = 700;
  double _dragStart = 0;

  late final NumberFormat numberFormat;
  Map<String, String> _spaceIdToDocId = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    numberFormat = NumberFormat.decimalPattern();
    widget.isOpenNotifier.addListener(_handleCloseSignal);
    if (widget.isInitial) {
      _sheetHeight = 0;
      Future.microtask(() => setState(() => _sheetHeight = 300));
    }
    _loadSpaces();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    widget.isOpenNotifier.removeListener(_handleCloseSignal);
    _fadeController.dispose();
    super.dispose();
  }

  void _handleCloseSignal() {
    if (!widget.isOpenNotifier.value) {
      _fadeController.reverse();
      setState(() => _sheetHeight = 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onClose();
      });
    }
  }

  Future<void> _loadSpaces() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('spaces')
        .get();

    if (!mounted) return;

    final mapping = <String, String>{};
    for (var doc in snapshot.docs) {
      final spaceId = doc['spaceId'] ?? '';
      mapping[spaceId] = doc.id;
    }
    setState(() => _spaceIdToDocId = mapping);
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dy;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = _dragStart - details.globalPosition.dy;
    setState(() {
      _sheetHeight = (_sheetHeight + delta).clamp(_minHeight, _maxHeight);
      _dragStart = details.globalPosition.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final midpoint = (_maxHeight + 300) / 2;

    if (_sheetHeight < 300 || velocity > 800) {
      _fadeController.reverse();
      setState(() => _sheetHeight = 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onClose();
      });
    } else {
      setState(() => _sheetHeight = velocity < -800 || _sheetHeight > midpoint ? _maxHeight : 300);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: _sheetHeight,
        curve: Curves.easeOut,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final warehouse = widget.warehouse;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (warehouse.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: warehouse.images.first,
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(warehouse.address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(warehouse.detailAddress),
          const SizedBox(height: 6),
          Text('가격: ${numberFormat.format(warehouse.price)}원'),
          Text('보관 공간: ${numberFormat.format(warehouse.count)}칸'),
          const SizedBox(height: 6),
          Text('등록일: ${warehouse.createdAt?.toLocal().toString().split(' ').first ?? ''}'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: widget.onTap,
                child: const Text('자세히 보기'),
              ),
              FavoriteButton(warehouse: warehouse),
            ],
          ),
          const SizedBox(height: 12),
          const Text('예약 가능한 공간', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildSpaceGrid(),
        ],
      ),
    );
  }

  Widget _buildSpaceGrid() {
    final layout = widget.warehouse.layout;
    final rows = layout['rows'] ?? 0;
    final cols = layout['columns'] ?? 0;

    if (rows <= 0 || cols <= 0) {
      return const Text('잘못된 배치 정보입니다.');
    }

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cols, (c) {
            final spaceId = '${String.fromCharCode(65 + r)}${c + 1}';
            final docId = _spaceIdToDocId[spaceId];

            return GestureDetector(
              onTap: () => _showReservationDialog(spaceId, docId),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(spaceId, style: const TextStyle(fontSize: 10)),
              ),
            );
          }),
        );
      }),
    );
  }

  void _showReservationDialog(String spaceId, String? docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$spaceId 예약'),
        content: const Text('이 공간을 예약하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (docId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReservationScreen(
                      warehouseId: widget.warehouse.id,
                      spaceDocId: docId,
                    ),
                  ),
                );
              }
            },
            child: const Text('예약'),
          ),
        ],
      ),
    );
  }
}
