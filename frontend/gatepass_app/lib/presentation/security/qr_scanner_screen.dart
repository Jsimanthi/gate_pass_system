// File: lib/presentation/security/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gatepass_app/services/local_database_service.dart';

class QrScannerScreen extends StatefulWidget {
  final ApiClient apiClient;

  const QrScannerScreen({super.key, required this.apiClient});

  @override
  State<QrScannerScreen> createState() => QrScannerScreenState();
}

class QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final LocalDatabaseService _localDatabaseService = LocalDatabaseService.instance;

  void handleScan(String value) async {
    controller.stop();

    setState(() {
      _isProcessing = true;
    });

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _localDatabaseService.insertScannedQRCode(value);
      setState(() {
        _isProcessing = false;
      });
      _showResultDialog(
        title: 'Offline Scan',
        details: {'message': 'QR code saved locally. Sync when online.'},
        isSuccess: true,
      );
    } else {
      try {
        final result = await widget.apiClient.verifyQrCode(value);

        setState(() {
          _isProcessing = false;
        });

        if (result['alcohol_test_required'] == true) {
          _showAlcoholTestDialog(result['gatepass_id']);
        } else {
          _showResultDialog(
            title: result['message'] ?? 'Validation Successful',
            details: result['gate_pass_details'] ?? {},
            isSuccess: true,
          );
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        _showResultDialog(
          title: 'Validation Failed',
          details: {'error': e.toString()},
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required Map<String, dynamic> details,
    required bool isSuccess,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              // WRAPPED THE TEXT WIDGET IN EXPANDED TO PREVENT OVERFLOW
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: details.entries.map((entry) {
                return Text('${entry.key}: ${entry.value}');
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                controller.start();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAlcoholTestDialog(int gatepassId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alcohol Test Required'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please perform an alcohol test on the driver.'),
                const SizedBox(height: 20),
                _image == null
                    ? const Text('No image selected.')
                    : Image.file(_image!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Take Photo'),
              onPressed: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (image != null) {
                  if (!mounted) return;
                  setState(() {
                    _image = File(image.path);
                  });
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _showAlcoholTestDialog(gatepassId);
                }
              },
            ),
            TextButton(
              child: const Text('Pass'),
              onPressed: () {
                _submitAlcoholTestResult(gatepassId, 'pass');
                if (!mounted) return;
                Navigator.of(context).pop();
                controller.start();
              },
            ),
            TextButton(
              child: const Text('Fail'),
              onPressed: () {
                _submitAlcoholTestResult(gatepassId, 'fail');
                if (!mounted) return;
                Navigator.of(context).pop();
                controller.start();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitAlcoholTestResult(int gatepassId, String result) async {
    if (_image == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo before submitting the result.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await widget.apiClient.post('api/gatepass/$gatepassId/alcohol_test/', {
        'result': result,
        'photo': _image,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alcohol test result submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting alcohol test result: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (!_isProcessing) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      handleScan(code);
                    }
                  }
                }
              },
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
