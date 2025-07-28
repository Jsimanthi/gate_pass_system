import 'package:flutter/material.dart';
import 'package:gatepass_app/core/api_client.dart';

class ReportsScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ReportsScreen({super.key, required this.apiClient});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Future<Map<String, dynamic>>? _summary;
  Future<List<dynamic>>? _logs;

  @override
  void initState() {
    super.initState();
    _summary = widget.apiClient.get('api/reports/logs/summary/').then((data) => data as Map<String, dynamic>);
    _logs = widget.apiClient.get('api/reports/logs/').then((data) => data as List<dynamic>);
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
              future: _summary,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final summary = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        Chip(label: Text('Total Entries: ${summary['total_entries']}')),
                        Chip(label: Text('Successful Entries: ${summary['successful_entries']}')),
                        Chip(label: Text('Failed Entries: ${summary['failed_entries']}')),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: Text('No summary data'));
                }
              },
            ),
            FutureBuilder<List<dynamic>>(
              future: _logs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final logs = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        title: Text('Action: ${log['action']}'),
                        subtitle: Text('Status: ${log['status']}'),
                        trailing: Text(log['timestamp']),
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
