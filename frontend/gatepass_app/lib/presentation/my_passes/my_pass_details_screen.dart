import 'package:flutter/material.dart';

class MyPassDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> pass;

  const MyPassDetailsScreen({super.key, required this.pass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Pass Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purpose: ${pass['purpose']?['name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Applicant: ${pass['person_name'] ?? 'N/A'}'),
            Text('Gate: ${pass['gate']?['name'] ?? 'N/A'}'),
            Text('Status: ${pass['status'] ?? 'N/A'}'),
            if (pass['vehicle'] != null) Text('Vehicle: ${pass['vehicle']?['vehicle_number'] ?? 'N/A'}'),
            if (pass['driver'] != null) Text('Driver: ${pass['driver']?['name'] ?? 'N/A'}'),
            Text('Entry: ${pass['entry_time'] ?? 'N/A'}'),
            Text('Exit: ${pass['exit_time'] ?? 'N/A'}'),
            Text('Created At: ${pass['created_at'] ?? 'N/A'}'),
            if (pass['created_by'] != null) Text('Created By: ${pass['created_by']?['username'] ?? 'N/A'}'),
            if (pass['approved_by'] != null) Text('Approved By: ${pass['approved_by']?['username'] ?? 'N/A'}'),
            if (pass['status'] == 'APPROVED' && pass['qr_code'] != null)
              Center(
                child: Image.network(pass['qr_code']),
              ),
          ],
        ),
      ),
    );
  }
}
