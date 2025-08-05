import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class MyPassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> pass;

  const MyPassDetailsScreen({super.key, required this.pass});

  @override
  State<MyPassDetailsScreen> createState() => _MyPassDetailsScreenState();
}

class _MyPassDetailsScreenState extends State<MyPassDetailsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _captureAndSave() async {
    try {
      final Uint8List? image = await _screenshotController.capture(
          delay: const Duration(milliseconds: 10));
      if (image != null) {
        final result = await ImageGallerySaver.saveImage(image);
        if (!mounted) return;
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pass saved to gallery')),
          );
        } else {
          throw Exception(result['errorMessage']);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save pass: $e')),
      );
    }
  }

  Future<void> _captureAndShare() async {
    try {
      final Uint8List? image = await _screenshotController.capture(
          delay: const Duration(milliseconds: 10));
      if (image != null) {
        final passDetails =
            'Pass for: ${widget.pass['person_name']}\nPurpose: ${widget.pass['purpose']?['name']}';
        final xFile = XFile.fromData(
          image,
          mimeType: 'image/png',
          name: 'gatepass.png',
        );
        await Share.shareXFiles([xFile], text: passDetails);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share pass: $e')),
      );
    }
  }

  Future<void> _captureAndPrint() async {
    try {
      final Uint8List? image = await _screenshotController.capture(
          delay: const Duration(milliseconds: 10));
      if (image != null) {
        await Printing.layoutPdf(
          onLayout: (format) async => image,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print pass: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gate Pass Details')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureAndSave,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureAndShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureAndPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPassDetails(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Purpose: ${widget.pass['purpose']?['name'] ?? 'N/A'}',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('Applicant: ${widget.pass['person_name'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Gate: ${widget.pass['gate']?['name'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Status: ${widget.pass['status'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          if (widget.pass['vehicle'] != null) ...[
            Text(
                'Vehicle: ${widget.pass['vehicle']?['vehicle_number'] ?? 'N/A'}'),
            const SizedBox(height: 8),
          ],
          if (widget.pass['driver'] != null) ...[
            Text('Driver: ${widget.pass['driver']?['name'] ?? 'N/A'}'),
            const SizedBox(height: 8),
          ],
          Text('Entry: ${widget.pass['entry_time'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Exit: ${widget.pass['exit_time'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          Text('Created At: ${widget.pass['created_at'] ?? 'N/A'}'),
          const SizedBox(height: 8),
          if (widget.pass['created_by'] != null) ...[
            Text(
                'Created By: ${widget.pass['created_by']?['username'] ?? 'N/A'}'),
            const SizedBox(height: 8),
          ],
          if (widget.pass['approved_by'] != null) ...[
            Text(
              'Approved By: ${widget.pass['approved_by']?['username'] ?? 'N/A'}',
            ),
            const SizedBox(height: 8),
          ],
          if (widget.pass['status'] == 'APPROVED' &&
              widget.pass['qr_code'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Image.network(widget.pass['qr_code'])),
            ),
        ],
      ),
    );
  }
}
