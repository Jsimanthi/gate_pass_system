import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  File? _image;
  final ImagePicker _picker = ImagePicker();

  void handleScan(String value) async {
    setState(() {
      _isProcessing = true;
      _scanResult = value;
    });

    try {
      final result = await widget.apiClient.verifyQrCode(value);
      if (result['alcohol_test_required'] == true) {
        _showAlcoholTestDialog(result['gatepass_id']);
      } else {
        setState(() {
          _verificationResult = result.toString();
        });
      }
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

  Future<void> _showAlcoholTestDialog(int gatepassId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alcohol Test Required'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please perform an alcohol test on the driver.'),
                const SizedBox(height: 20),
                _image == null ? const Text('No image selected.') : Image.file(_image!),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Take Photo'),
              onPressed: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _image = File(image.path);
                  });
                  // Rebuild the dialog with the new image
                  Navigator.of(context).pop();
                  _showAlcoholTestDialog(gatepassId);
                }
              },
            ),
            TextButton(
              child: const Text('Pass'),
              onPressed: () {
                _submitAlcoholTestResult(gatepassId, 'pass');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Fail'),
              onPressed: () {
                _submitAlcoholTestResult(gatepassId, 'fail');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitAlcoholTestResult(int gatepassId, String result) async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo before submitting the result.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await widget.apiClient.post(
        'api/gatepass/$gatepassId/alcohol_test/',
        {
          'result': result,
          'photo': _image,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alcohol test result submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
