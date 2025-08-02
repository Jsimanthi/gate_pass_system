import 'package:flutter/material.dart';

class MyPassDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> pass;

  const MyPassDetailsScreen({super.key, required this.pass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gate Pass Details')),
      // Wrap the content in a SingleChildScrollView to prevent overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the main purpose with a prominent style
              Text(
                'Purpose: ${pass['purpose']?['name'] ?? 'N/A'}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Applicant Details
              Text('Applicant: ${pass['person_name'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              // Gate and Status
              Text('Gate: ${pass['gate']?['name'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              Text('Status: ${pass['status'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              // Conditional details for vehicle and driver
              if (pass['vehicle'] != null) ...[
                Text('Vehicle: ${pass['vehicle']?['vehicle_number'] ?? 'N/A'}'),
                const SizedBox(height: 8),
              ],
              if (pass['driver'] != null) ...[
                Text('Driver: ${pass['driver']?['name'] ?? 'N/A'}'),
                const SizedBox(height: 8),
              ],

              // Time-related details
              Text('Entry: ${pass['entry_time'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              Text('Exit: ${pass['exit_time'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              Text('Created At: ${pass['created_at'] ?? 'N/A'}'),
              const SizedBox(height: 8),

              // Conditional details for created by and approved by
              if (pass['created_by'] != null) ...[
                Text('Created By: ${pass['created_by']?['username'] ?? 'N/A'}'),
                const SizedBox(height: 8),
              ],
              if (pass['approved_by'] != null) ...[
                Text(
                  'Approved By: ${pass['approved_by']?['username'] ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
              ],

              // Display the QR code if the status is APPROVED
              if (pass['status'] == 'APPROVED' && pass['qr_code'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: Image.network(pass['qr_code'])),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
