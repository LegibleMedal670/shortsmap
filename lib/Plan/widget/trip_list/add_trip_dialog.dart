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
            if (tripName != null && startDate != null && endDate != null) {
              final days = Trip.generateDays(startDate!, endDate!);
              
              final newTrip = Trip(
                name: tripName!,
                start: startDate!,
                end: endDate!,
                days: days,
              );
              
              widget.onAddTrip(newTrip);
              Navigator.pop(context);
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