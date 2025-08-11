import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';

class GenerateQRScreen extends StatelessWidget {
  final ApiClient apiClient;

  const GenerateQRScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    // Construct the full URL for the image
    final qrCodeUrl = '${apiClient.baseUrl}/api/core-data/visitor-qr-code/';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Form QR Code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Scan this QR code to access the visitor form.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              InteractiveViewer(
                child: Image.network(
                  qrCodeUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 100, color: Colors.red);
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'URL: $qrCodeUrl',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
