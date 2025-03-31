import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/warehouse.dart';
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

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  double _sheetHeight = 300;
  final double _minHeight = 0;
  final double _maxHeight = 700;
  double _dragStart = 0;

  final NumberFormat numberFormat = NumberFormat.decimalPattern();
  Map<String, String> spaceIdToDocId = {}; // ✅ spaceId → docId 매핑 저장

  @override
  void initState() {
    super.initState();
    widget.isOpenNotifier.addListener(_handleCloseSignal);

    if (widget.isInitial) {
      _sheetHeight = 0;
      Future.microtask(() {
        setState(() {
          _sheetHeight = 300;
        });
      });
    } else {
      _sheetHeight = 300;
    }

    _loadSpaces(); // ✅ 공간 문서 로드
  }

  Future<void> _loadSpaces() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('spaces')
        .get();

    final mapping = <String, String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final spaceId = data['spaceId'] ?? '';
      mapping[spaceId] = doc.id;
    }

    setState(() {
      spaceIdToDocId = mapping;
    });
  }

  void _handleCloseSignal() {
    if (!widget.isOpenNotifier.value) {
      setState(() => _sheetHeight = 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onClose();
      });
    }
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
    final delta = details.velocity.pixelsPerSecond.dy;

    if (_sheetHeight < 300) {
      setState(() => _sheetHeight = 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onClose();
      });
    } else {
      if (delta > 0) {
        setState(() => _sheetHeight = 300);
      } else if (delta < 0) {
        setState(() => _sheetHeight = _maxHeight);
      } else {
        if ((_sheetHeight - 300) < (_maxHeight - _sheetHeight)) {
          setState(() => _sheetHeight = 300);
        } else {
          setState(() => _sheetHeight = _maxHeight);
        }
      }
    }
  }

  @override
  void dispose() {
    widget.isOpenNotifier.removeListener(_handleCloseSignal);
    super.dispose();
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
        child: Offstage(
          offstage: _sheetHeight == 0,
          child: Column(
            children: [
              GestureDetector(
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.warehouse.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.warehouse.images.first,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(widget.warehouse.address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(widget.warehouse.detailAddress),
                      const SizedBox(height: 6),
                      Text('가격: ${numberFormat.format(widget.warehouse.price)}원'),
                      Text('보관 공간: ${numberFormat.format(widget.warehouse.count)}칸'),
                      const SizedBox(height: 6),
                      Text('등록일: ${widget.warehouse.createdAt?.toLocal().toString().split(' ').first}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: widget.onTap,
                            child: const Text('자세히 보기'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _sheetHeight = 0);
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) widget.onClose();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("예약 가능한 공간", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _buildSpaceGrid(widget.warehouse),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceGrid(Warehouse warehouse) {
    final rows = warehouse.layout['rows'] ?? 0;
    final cols = warehouse.layout['columns'] ?? 0;

    if (rows <= 0 || cols <= 0) return const Text('잘못된 배치 정보입니다.');

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cols, (c) {
            final spaceId = '${String.fromCharCode(65 + r)}${c + 1}';
            final spaceDocId = spaceIdToDocId[spaceId];

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('$spaceId 예약'),
                    content: const Text('이 공간을 예약하시겠습니까?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (spaceDocId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReservationScreen(
                                  warehouseId: warehouse.id,
                                  spaceDocId: spaceDocId,
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
              },
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
}
