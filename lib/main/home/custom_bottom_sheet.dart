import 'package:flutter/material.dart';
import '../../data/warehouse.dart';

class CustomBottomSheet extends StatefulWidget {
  final Warehouse warehouse;
  final VoidCallback onClose;
  final VoidCallback onTap;
  final bool isInitial; // ⭐ 추가

  const CustomBottomSheet({
    super.key,
    required this.warehouse,
    required this.onClose,
    required this.onTap,
    this.isInitial = true, // 기본값 true
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  double _sheetHeight = 300;
  final double _minHeight = 0;
  final double _maxHeight = 850;
  double _dragStart = 0;

  @override
  void initState() {
    super.initState();

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
        widget.onClose();
      });
    } else {
      if (delta > 0) {
        setState(() => _sheetHeight = 300);
      } else if (delta < 0){
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
        child: Column(
          children: [
            // 드래그 핸들바
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
            // 스크롤 가능한 내용
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
                    Text('가격: ${widget.warehouse.price}원'),
                    Text('보관 공간: ${widget.warehouse.count}칸'),
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
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
