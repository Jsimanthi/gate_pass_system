import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final ApiClient apiClient;

  const QrScannerScreen({super.key, required this.apiClient});

  @override
  State<QrScannerScreen> createState() => QrScannerScreenState();
}

class QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _scanResult;
  String? _verificationResult;

  void handleScan(String value) async {
    setState(() {
      _isProcessing = true;
      _scanResult = value;
    });

    try {
      final result = await widget.apiClient.verifyQrCode(value);
      setState(() {
        _verificationResult = result.toString();
      });
    } catch (e) {
      setState(() {
        _verificationResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
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
          if (_scanResult != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scan Result: $_scanResult',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          if (_verificationResult != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Verification Result: $_verificationResult',
                style: const TextStyle(fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }
}
