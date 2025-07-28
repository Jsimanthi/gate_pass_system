import 'package:flutter/material.dart';
import 'package:gatepass_app/api_service.dart';
import 'package:gatepass_app/qr_scanner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QrScannerScreen(),
              ),
            );
            if (result != null) {
              try {
                final verificationResult = await ApiService.verifyQrCode(result);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Verification result: $verificationResult'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                  ),
                );
              }
            }
          },
          child: const Text('Scan QR Code'),
        ),
      ),
    );
  }
}
