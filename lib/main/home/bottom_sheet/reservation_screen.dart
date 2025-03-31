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
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final Set<DateTime> reservedDates = {};

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

      DateTime current = start;
      while (!current.isAfter(end)) {
        dates.add(DateTime(current.year, current.month, current.day));
        current = current.add(const Duration(days: 1));
      }
    }

    setState(() {
      reservedDates.addAll(dates);
    });
  }

  bool _isDateAvailable(DateTime day) {
    return !reservedDates.contains(DateTime(day.year, day.month, day.day));
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime tempDate = startDate ?? today;

    // ✅ 예약 안 된 가장 가까운 날짜 찾기
    while (!_isDateAvailable(tempDate)) {
      tempDate = tempDate.add(const Duration(days: 1));
      if (tempDate.difference(today).inDays > 365) {
        // 1년 내에 가능한 날짜 없음
        return;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: tempDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: _isDateAvailable,
    );

    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? now,
      firstDate: startDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
      selectableDayPredicate: _isDateAvailable,
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => endTime = picked);
    }
  }

  Future<void> _saveReservation() async {
    if (startDate == null || endDate == null || startTime == null || endTime == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      startTime!.hour,
      startTime!.minute,
    );

    final end = DateTime(
      endDate!.year,
      endDate!.month,
      endDate!.day,
      endTime!.hour,
      endTime!.minute,
    );

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 시작일보다 이후여야 합니다.')),
      );
      return;
    }

    if (_hasOverlap()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 기간에 이미 예약이 있습니다.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouseId)
        .collection('spaces')
        .doc(widget.spaceDocId)
        .collection('reservations')
        .doc(start.toIso8601String()) // ✅ 시작 시간을 문서 ID로
        .set({
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'reservedBy': user.uid,
      'reservedByName': user.displayName ?? '알 수 없음',
    });

    if (mounted) Navigator.of(context).pop(); // 등록 후 뒤로
  }

  bool _hasOverlap() {
    if (startDate == null || endDate == null) return false;
    for (DateTime day = startDate!;
    !day.isAfter(endDate!);
    day = day.add(const Duration(days: 1))) {
      if (reservedDates.contains(DateTime(day.year, day.month, day.day))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예약 시간 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('시작 날짜'),
              subtitle: Text(startDate != null ? _dateFormat.format(startDate!) : '시작 날짜를 선택하세요'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickStartDate,
            ),
            ListTile(
              title: const Text('시작 시간'),
              subtitle: Text(startTime != null ? startTime!.format(context) : '시작 시간을 선택하세요'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickStartTime,
            ),
            const Divider(),
            ListTile(
              title: const Text('종료 날짜'),
              subtitle: Text(endDate != null ? _dateFormat.format(endDate!) : '종료 날짜를 선택하세요'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickEndDate,
            ),
            ListTile(
              title: const Text('종료 시간'),
              subtitle: Text(endTime != null ? endTime!.format(context) : '종료 시간을 선택하세요'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickEndTime,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (startDate != null && endDate != null && startTime != null && endTime != null)
                  ? _saveReservation
                  : null,
              child: const Text('예약하기'),
            ),
          ],
        ),
      ),
    );
  }
}
