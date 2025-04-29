// TODO : 최적화 및 상태 최상단화

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/warehouse.dart';

class WarehouseManagement extends StatefulWidget {
  final Warehouse warehouse;  // 창고 객체
  const WarehouseManagement({super.key, required this.warehouse});  // 창고 정보 이전 screen에서 받앙모

  @override
  State<WarehouseManagement> createState() => _WarehouseManagementState();
}

class _WarehouseManagementState extends State<WarehouseManagement> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');  // 날짜 형식
  DateTime? startDate;  // 시작날짜
  DateTime? endDate;    // 끝날짜

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(  //
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? now,
      firstDate: startDate ?? now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Future<void> _addUnavailablePeriod() async {
    if (startDate == null || endDate == null) return;
    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 시작일보다 이후여야 합니다.')),
      );
      return;
    }

    await FirebaseFirestore.instance    // 현제 창고 컬렉션 내의 unavailable 컬렉션에
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('unavailable')    // 사용 불가 날짜 설정
        .add({
      'start': startDate!.toIso8601String(),  // 시작날짜
      'end': endDate!.toIso8601String(),    // 끝날짜
    });

    setState(() {
      startDate = null;
      endDate = null;
    });
  }

  Stream<QuerySnapshot> _getUnavailablePeriods() {    // 사용 불가 날짜 가져오기
    return FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('unavailable')
        .orderBy('start')
        .snapshots();
  }

  Stream<QuerySnapshot> _getSpaces() {
    return FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('spaces')
        .snapshots();
  }

  Future<String> _getUserName(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['displayName'] ?? '알 수 없음';
  }

  Widget _buildLayoutGrid(Map<String, dynamic> spaceStatus) {
    final rows = widget.warehouse.layout['rows'] as int;
    final cols = widget.warehouse.layout['columns'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('창고 배치도 (사용 중인 공간은 회색)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          children: List.generate(rows, (r) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cols, (c) {
                final spaceId = '${String.fromCharCode(65 + r)}${c + 1}';
                final isInUse = spaceStatus[spaceId] ?? false;

                return Container(
                  margin: const EdgeInsets.all(4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isInUse ? Colors.grey[400] : Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(spaceId, style: const TextStyle(fontSize: 10)),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Future<Map<String, bool>> _fetchCurrentSpaceStatus(Map<String, bool> ans) async {
    return ans;
  }

  Future<Map<String, dynamic>> _getUserInfo(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    return {
      'displayName': data?['displayName'] ?? '알 수 없음',
      'email': data?['email'] ?? '알 수 없음',
      'photoUrl': data?['photoURL'] ?? null,
    };
  }

  Future<void> _cancelReservation(String spaceId, String reservationDocId) async {
    await FirebaseFirestore.instance
        .collection('warehouse')
        .doc(widget.warehouse.id)
        .collection('spaces')
        .doc(spaceId)
        .collection('reservations')
        .doc(reservationDocId)
        .delete();
  }

  void _showUsageDetailDialog(String spaceId, QueryDocumentSnapshot latest) async {
    final userInfo = await _getUserInfo(latest['reservedBy']);
    final start = DateTime.parse(latest['start']);
    final end = DateTime.parse(latest['end']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$spaceId 사용 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userInfo['photoUrl'] != null)
              CircleAvatar(
                backgroundImage: NetworkImage(userInfo['photoUrl']),
                radius: 30,
              ),
            const SizedBox(height: 10),
            Text('이름: ${userInfo['displayName']}'),
            Text('이메일: ${userInfo['email']}'),
            const SizedBox(height: 10),
            Text('${_dateFormat.format(start)} ~ ${_dateFormat.format(end)} 사용 중'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }


  void _showReservationDialog(String spaceId, List<QueryDocumentSnapshot> reservations) async {
    final reserverInfoList = await Future.wait(reservations.map((res) => _getUserInfo(res['reservedBy'])));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$spaceId 예약 내역'),
        content: SizedBox(
          width: 300,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reserverInfoList.length,
              itemBuilder: (context, i) {
                final info = reserverInfoList[i];
                final resDoc = reservations[i];
                final start = DateTime.parse(resDoc['start']);
                final end = DateTime.parse(resDoc['end']);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    if (info['photoUrl'] != null)
                      Row(
                        children: [
                          CircleAvatar(backgroundImage: NetworkImage(info['photoUrl']), radius: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이름: ${info['displayName']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '이메일: ${info['email']}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Text(
                      '예약 기간: ${_dateFormat.format(start)} ~ ${_dateFormat.format(end)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('예약 취소 확인'),
                              content: const Text('정말 이 예약을 취소하시겠습니까?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('아니요')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('네')),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _cancelReservation(spaceId, resDoc.id);
                            Navigator.pop(context); // 기존 다이얼로그 닫기
                            _showReservationDialog(spaceId, reservations.where((e) => e.id != resDoc.id).toList()); // 다시 열기
                          }
                        },
                        icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                        label: const Text('예약 취소', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, bool> usageMap = {};

    return Scaffold(
      appBar: AppBar(title: const Text('창고 관리')),
      body: SingleChildScrollView(  // ✅ 스크롤 가능하게 만듦
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.warehouse.address, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(widget.warehouse.detailAddress),
              const Divider(height: 32),
              FutureBuilder<Map<String, bool>>(
                future: _fetchCurrentSpaceStatus(usageMap),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildLayoutGrid(snapshot.data!);
                },
              ),
              const Divider(height: 32),
              const Text('전체 예약 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // ✅ 스크롤 가능한 공간 안에서만 ListView.builder 사용 가능
              StreamBuilder<QuerySnapshot>(
                stream: _getSpaces(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final spaces = snapshot.data!.docs;

                  return Column(      // 예약목록 컬럼
                    children: List.generate(spaces.length, (index) {
                      final space = spaces[index];       // 공간
                      final spaceId = space['spaceId'];  // 공간 id

                      return FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('warehouse')    // 현제창고의 공간들에서 예약목록 가져오기
                            .doc(widget.warehouse.id)
                            .collection('spaces')
                            .doc(space.id)
                            .collection('reservations')
                            .orderBy('start')     // 시작날짜 기준으로 정렬
                            .get(),
                        builder: (context, resSnap) {       // 빌더 - 내가 불러온 context랑 스냅샷을 매개변수로 받아 함수실행
                          if (!resSnap.hasData) return const SizedBox();    // 스탭샷에 데이터 없으면 빈박스

                          final reservations = resSnap.data!.docs;  // resSnap.data - 문서들 가져오고
                          if (reservations.isEmpty) {   // 만약 예약목록이 없으면
                            usageMap[spaceId] = false;  // 사용중 x 아 사용중인지 확인하려고 ??
                            return SizedBox();    //
                          }

                          final latest = reservations.first;    // 최근예약 이미 정렬됐기 떄문에 first가 가장 최근
                          final start = DateTime.parse(latest['start']);
                          final end = DateTime.parse(latest['end']);
                          final reservedBy = latest['reservedBy'];
                          final now = DateTime.now();

                          final isInUse = start.isBefore(now) && end.isAfter(now);
                          if (isInUse){
                            usageMap[spaceId] = true;
                            reservations.removeAt(0);
                          }

                          return FutureBuilder<String>(
                            future: _getUserName(reservedBy),
                            builder: (context, nameSnap) {
                              final userName = nameSnap.data ?? '예약자';
                              return ListTile(
                                title: Text(spaceId),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isInUse)
                                      OutlinedButton.icon(
                                        onPressed: () => _showUsageDetailDialog(spaceId, latest),
                                        icon: const Icon(Icons.play_circle_fill, size: 16),
                                        label: const Text('사용 중'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,                     // 테두리/글자색
                                          side: const BorderSide(color: Colors.red),       // 테두리
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 13),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                    SizedBox(width: 20,),
                                    if (reservations.length > 0)  // 사용 중인 예약 빼고 대기 예약이 있다면
                                      OutlinedButton.icon(
                                        onPressed: () => _showReservationDialog(spaceId, reservations),
                                        icon: const Icon(Icons.event_note, size: 16),
                                        label: Text('예약 ${reservations.length}'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: const BorderSide(color: Colors.blue),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          textStyle: const TextStyle(fontSize: 13),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
