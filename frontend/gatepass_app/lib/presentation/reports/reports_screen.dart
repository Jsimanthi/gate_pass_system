// File: lib/presentation/reports/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';

class ReportsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ReportsScreen({super.key, required this.apiClient});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Changed _summary and _logs to be nullable and initialized in initState
  Future<Map<String, dynamic>>? _summaryFuture;
  Future<List<dynamic>>? _logsFuture;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    // Fetch summary data from an existing endpoint, e.g., daily_visitor_summary
    _summaryFuture = widget.apiClient.get('/api/reports/daily_visitor_summary/').then((data) {
      // Ensure data is treated as a Map for summary
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        // Handle unexpected data format, e.g., by returning an empty map or throwing an error
        debugPrint('Warning: daily_visitor_summary did not return a Map. Received: $data');
        return {};
      }
    });

    // Fetch logs data: Since daily_visitor_summary does not return a list of logs,
    // we'll explicitly return an empty list or null, and the UI will reflect this.
    // If you have another backend endpoint that provides actual log entries,
    // you would use that URL here instead.
    _logsFuture = Future.value([]); // Initialize with an empty list for now
    // If you had an actual logs endpoint, it would look like this:
    // _logsFuture = widget.apiClient.get('/api/reports/actual_logs_endpoint/').then((data) {
    //   if (data is Map<String, dynamic> && data.containsKey('results') && data['results'] is List) {
    //     return data['results'] as List<dynamic>;
    //   } else if (data is List) {
    //     return data;
    //   } else {
    //     debugPrint('Warning: actual_logs_endpoint did not return expected logs format. Received: $data');
    //     return [];
    //   }
    // });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _summaryFuture, // Use the new future variable
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading summary: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final summary = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        Chip(label: Text('Total Entries: ${summary['total_gate_passes'] ?? 'N/A'}')), // Corrected key
                        Chip(label: Text('Unique Visitors: ${summary['unique_visitors'] ?? 'N/A'}')), // Corrected key
                        Chip(label: Text('Unique Vehicles: ${summary['unique_vehicles'] ?? 'N/A'}')), // Corrected key
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text('No summary data available'));
                }
              },
            ),
            const Divider(), // Add a divider for better separation
            FutureBuilder<List<dynamic>>(
              future: _logsFuture, // Use the new future variable
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading logs: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final logs = snapshot.data!;
                  if (logs.isEmpty) {
                    // Display message when no logs are available from this endpoint
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Detailed logs not available from this endpoint.', textAlign: TextAlign.center),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      // These keys are placeholders as daily_visitor_summary doesn't provide them
                      return ListTile(
                        title: Text('Visitor: ${log['visitor_name'] ?? 'N/A'}'),
                        subtitle: Text('Status: ${log['status'] ?? 'N/A'} - Time: ${log['timestamp'] ?? 'N/A'}'),
                        trailing: Text('Gate: ${log['gate_name'] ?? 'N/A'}'),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No logs found'));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
