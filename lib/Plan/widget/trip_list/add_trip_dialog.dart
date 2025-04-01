import 'package:flutter/material.dart';
import '../../models/trip.dart';

class AddTripDialog extends StatefulWidget {
  final Function(Trip) onAddTrip;

  const AddTripDialog({
    Key? key,
    required this.onAddTrip,
  }) : super(key: key);

  @override
  State<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  String? tripName;
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add new trip!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (val) => tripName = val,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              try {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    startDate = picked.start;
                    endDate = picked.end;
                  });
                  print('날짜 선택: ${_formatDate(picked.start)} ~ ${_formatDate(picked.end)}');
                } else {
                  print('날짜 선택이 취소되었습니다.');
                }
              } catch (e) {
                print('날짜 선택 중 오류 발생: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('날짜 선택 오류: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              startDate != null && endDate != null
                  ? "${_formatDate(startDate!)} ~ ${_formatDate(endDate!)}"
                  : 'Select Date Range',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              if (tripName == null || tripName!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('여행 이름을 입력해주세요'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              if (startDate == null || endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('여행 날짜를 선택해주세요'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              print('여행 생성 시작: $tripName, $startDate ~ $endDate');
              
              final days = Trip.generateDays(startDate!, endDate!);
              print('생성된 날짜 수: ${days.length}');
              
              // 날짜가 제대로 생성되었는지 확인
              if (days.isEmpty) {
                print('경고: 생성된 날짜 리스트가 비어 있습니다!');
                // 하루라도 추가
                days.add(startDate!);
                print('기본 날짜 추가: $startDate');
              }
              
              final newTrip = Trip(
                name: tripName!,
                start: startDate!,
                end: endDate!,
                days: days,
              );
              
              print('새 여행 객체 생성 완료');
              widget.onAddTrip(newTrip);
              Navigator.pop(context);
            } catch (e) {
              print('여행 생성 중 오류 발생: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('오류 발생: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}