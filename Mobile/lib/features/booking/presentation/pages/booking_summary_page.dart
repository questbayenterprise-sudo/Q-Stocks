// lib/features/booking/presentation/pages/booking_summary_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class BookingSummaryPage extends StatelessWidget {
  final DateTime date;
  final String time;
  final String venue;
  final String? bookingRef;
  final int? bookingId;

  const BookingSummaryPage({
    super.key,
    required this.date,
    required this.time,
    required this.venue,
    this.bookingRef,
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    // QR data: use booking_ref if available, else booking_id
    final String bookingData = bookingRef ?? 'booking_id:${bookingId ?? 0}';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Confirmed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share("Check out my turf booking!\n$bookingData"),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("Show this QR at the Venue", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            QrImageView(
              data: bookingData,
              version: QrVersions.auto,
              size: 250.0,
              embeddedImage: const AssetImage('assets/images/logo.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(50, 50),
              ),
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
            const SizedBox(height: 20),
            Text(venue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            Text(time),
            Text(DateFormat('EEEE, MMM dd').format(date)),
          ],
        ),
      ),
    );
  }
}