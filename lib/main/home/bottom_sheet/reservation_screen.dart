import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservationScreen extends StatefulWidget {
  final String warehouseId;
  final String spaceDocId;

  const ReservationScreen({
    super.key,
    required this.warehouseId,
    required this.spaceDocId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final Set<DateTime> _reservedDates = {};

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
  }

  Future<void> _loadReservedDates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouseId)
        .collection('spaces')
        .doc(widget.spaceDocId)
        .collection('reservations')
        .get();

    final Set<DateTime> dates = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final start = DateTime.parse(data['start']);
      final end = DateTime.parse(data['end']);

      for (var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))) {
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }

    setState(() => _reservedDates.addAll(dates));
  }

  bool _isDateAvailable(DateTime day) {
    return !_reservedDates.contains(DateTime(day.year, day.month, day.day));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = firstDate.add(const Duration(days: 365));

    final initial = isStart ? _startDate ?? firstDate : _endDate ?? _startDate ?? firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: _isDateAvailable,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveReservation() async {
    if (_startDate == null || _endDate == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_endDate!.isBefore(_startDate!)) {
      _showMessage('종료일은 시작일 이후여야 합니다.');
      return;
    }

    if (_hasOverlap()) {
      _showMessage('선택한 날짜 중 이미 예약된 날짜가 있습니다.');
      return;
    }

    await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouseId)
        .collection('spaces')
        .doc(widget.spaceDocId)
        .collection('reservations')
        .doc(_startDate!.toIso8601String())
        .set({
      'start': _startDate!.toIso8601String(),
      'end': _endDate!.toIso8601String(),
      'reservedBy': user.uid,
      'reservedByName': user.displayName ?? '알 수 없음',
    });

    if (mounted) Navigator.of(context).pop();
  }

  bool _hasOverlap() {
    for (var date = _startDate!;
    !date.isAfter(_endDate!);
    date = date.add(const Duration(days: 1))) {
      if (_reservedDates.contains(DateTime(date.year, date.month, date.day))) {
        return true;
      }
    }
    return false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예약 날짜 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('시작 날짜'),
              subtitle: Text(
                _startDate != null ? _dateFormat.format(_startDate!) : '시작 날짜를 선택하세요',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              title: const Text('종료 날짜'),
              subtitle: Text(
                _endDate != null ? _dateFormat.format(_endDate!) : '종료 날짜를 선택하세요',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_startDate != null && _endDate != null) ? _saveReservation : null,
              child: const Text('예약하기'),
            ),
          ],
        ),
      ),
    );
  }
}