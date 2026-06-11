import 'package:flutter/material.dart';

class VenueSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double price;
  final String label;

  VenueSlot({
    required this.startTime,
    required this.endTime,
    required this.price,
    this.label = '',
  });

  // Helper to format TimeOfDay to "6:00AM"
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute$period";
  }

  // New method for the specific API structure
  Map<String, String> toApiJson() => {
    "ST": _formatTime(startTime),
    "ET": _formatTime(endTime),
    "PR": price.toInt().toString(),
  };

  Map<String, dynamic> toJson() => {
    'start_time': '${startTime.hour}:${startTime.minute}',
    'end_time': '${endTime.hour}:${endTime.minute}',
    'price': price,
    'label': label,
  };
}
